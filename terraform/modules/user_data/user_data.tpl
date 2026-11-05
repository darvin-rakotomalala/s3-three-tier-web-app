#!/bin/bash
# NOTE: this file is rendered by Terraform templatefile().
#   - The SSM parameter name is injected by Terraform (see Parameter_Name below).
#   - Shell variables written with braces must be escaped with a doubled dollar sign
#     before the opening brace. Plain $VAR and $(cmd) need no escaping.

############################################
# System update
############################################
yum update -y
if [ $? -eq 0 ]; then
    echo "Updated the instance successfully."
else
    echo "Failed to update the instance."
    exit 1
fi

############################################
# Base packages: unzip, jq, Java 21, psql client 16, stress (load testing)
# - curl is already present on AL2023 (curl-minimal)
# - AWS CLI v2 and the SSM agent are preinstalled on AL2023
############################################
yum install -y unzip jq java-21-amazon-corretto-headless

# psql 16 client to match the RDS server major version
yum install -y postgresql16

# Load-testing tool (AL2023 has no "stress" package; stress-ng is the equivalent)
yum install -y stress-ng || echo "stress-ng not available, skipping."

############################################
# SSM Agent (preinstalled on AL2023 - ensure it is enabled and running)
############################################
systemctl enable --now amazon-ssm-agent || true

############################################
# Instance metadata (IMDSv2) -> AWS region
############################################
# Creates token to authenticate and retrieve instance metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
if [ $? -eq 0 ]; then
    echo "Created token for instance metadata."
else
    echo "Failed to create token."
    exit 1
fi

# Set the AWS region using the token
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/placement/region)
if [ $? -eq 0 ]; then
    export AWS_DEFAULT_REGION=$AWS_REGION
    echo "Setting AWS Region to: $AWS_DEFAULT_REGION"
else
    echo "Failed to fetch AWS region."
    exit 1
fi

############################################
# Application: fetch the JAR from S3 and run it as a systemd service
# - The systemd units run on EVERY boot, including when an instance is started
#   from the Stopped warm pool (user_data itself only runs on first boot).
# - Keep these values in sync with the workflow variables
#   (S3_BUCKET = jar_bucket_name, JAR_NAME, APP_DIR) and the target app port.
############################################
S3_BUCKET="ce-dev-ec2-web-app-backend-jar-bucket-69127"
JAR_NAME="ec2-web-app-backend.jar"
APP_DIR="/opt/app"

mkdir -p "$APP_DIR"
chown ec2-user:ec2-user "$APP_DIR"

cat > /etc/default/springboot-app << ENV
S3_BUCKET=$${S3_BUCKET}
JAR_NAME=$${JAR_NAME}
APP_DIR=$${APP_DIR}
AWS_DEFAULT_REGION=$${AWS_REGION}
JAVA_OPTS=-Xmx512m -Xms256m
ENV

# Downloads the latest JAR; retries while IAM credentials / network settle.
# If S3 is unreachable but a JAR is already on disk, keep using that one.
cat > /usr/local/bin/fetch-app-jar.sh << 'SCRIPT'
#!/bin/bash
for i in $(seq 1 10); do
  if /usr/bin/aws s3 cp "s3://$${S3_BUCKET}/$${JAR_NAME}" "$${APP_DIR}/$${JAR_NAME}"; then
    chown ec2-user:ec2-user "$${APP_DIR}/$${JAR_NAME}"
    exit 0
  fi
  echo "JAR download failed (attempt $i), retrying..."
  sleep 10
done
[ -f "$${APP_DIR}/$${JAR_NAME}" ] && exit 0
exit 1
SCRIPT
chmod +x /usr/local/bin/fetch-app-jar.sh

cat > /etc/systemd/system/springboot-app-fetch.service << 'UNIT'
[Unit]
Description=Fetch latest Spring Boot JAR from S3
After=network-online.target
Wants=network-online.target
Before=springboot-app.service

[Service]
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=/etc/default/springboot-app
ExecStart=/usr/local/bin/fetch-app-jar.sh

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/systemd/system/springboot-app.service << 'UNIT'
[Unit]
Description=Spring Boot CRUD application
Requires=springboot-app-fetch.service
After=springboot-app-fetch.service network-online.target

[Service]
User=ec2-user
WorkingDirectory=/opt/app
EnvironmentFile=/etc/default/springboot-app
ExecStart=/usr/bin/java $JAVA_OPTS -jar $${APP_DIR}/$${JAR_NAME}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable springboot-app-fetch.service springboot-app.service
# If the JAR isn't in S3 yet (very first deploy), the app simply stays stopped until the workflow runs.
systemctl start springboot-app-fetch.service springboot-app.service || true

############################################
# Logging: rsyslog + CloudWatch Agent
############################################
# Install rsyslog so /var/log/messages and /var/log/secure get created
yum install -y rsyslog
systemctl enable --now rsyslog

# Install the CloudWatch Agent
yum install -y amazon-cloudwatch-agent
if [ $? -eq 0 ]; then
    echo "Installed Amazon CloudWatch Agent."
else
    echo "Failed to install Amazon CloudWatch Agent."
    exit 1
fi

# Fetch CloudWatch agent configuration from SSM Parameter Store
CONFIG=$(aws ssm get-parameter --name "${Parameter_Name}" --with-decryption --query "Parameter.Value" --output text)
if [ $? -eq 0 ]; then
    echo "Fetched CloudWatch agent configuration."
else
    echo "Failed to fetch CloudWatch agent configuration."
    exit 1
fi

# Save the configuration to a file
echo "$CONFIG" > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
if [ $? -eq 0 ]; then
    echo "Saved CloudWatch agent configuration to file."
else
    echo "Failed to save CloudWatch agent configuration."
    exit 1
fi

# Start the CloudWatch agent with the new configuration
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
if [ $? -eq 0 ]; then
    echo "Started CloudWatch agent with new configuration."
else
    echo "Failed to start CloudWatch agent."
    exit 1
fi

# Ensure the CloudWatch agent starts on system boot
systemctl enable amazon-cloudwatch-agent
if [ $? -eq 0 ]; then
    echo "Configured CloudWatch agent to start on boot."
else
    echo "Failed to enable CloudWatch agent on boot."
    exit 1
fi
