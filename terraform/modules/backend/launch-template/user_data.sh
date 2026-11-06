#!/bin/bash
############################################
# Base packages: curl, AWS CLI, Java, psql client, stress (load testing)
############################################
apt-get update -y
apt-get install -y curl unzip jq gnupg lsb-release openjdk-21-jdk stress

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

# Add the official PostgreSQL (PGDG) apt repo so we can install psql 16
# to match the RDS server major version (avoids the v14 client / v16 server mismatch)
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  | tee /etc/apt/sources.list.d/pgdg.list
apt-get update -y
apt-get install -y postgresql-client-16

############################################
# SSM Agent (preinstalled via snap on Ubuntu 22.04 - ensure it is enabled)
############################################
snap install amazon-ssm-agent --classic || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || systemctl enable amazon-ssm-agent || true
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || systemctl start amazon-ssm-agent || true

############################################
# Application: fetch the JAR from S3 and run it as a systemd service
# - Runs on EVERY boot, including when an instance is started from the
#   Stopped warm pool (user_data itself only runs on first boot).
# - Keep these values in sync with the workflow variables
#   (S3_BUCKET = jar_bucket_name, JAR_NAME, APP_DIR) and the target app port.
############################################
S3_BUCKET="ce-dev-springboot-jar-bucket-69127"
JAR_NAME="spring-boot-crud-example.jar"
APP_DIR="/opt/app"
AWS_REGION="us-east-1"

mkdir -p "$APP_DIR"
chown ubuntu:ubuntu "$APP_DIR"

cat > /etc/default/springboot-app << ENV
S3_BUCKET=${S3_BUCKET}
JAR_NAME=${JAR_NAME}
APP_DIR=${APP_DIR}
AWS_DEFAULT_REGION=${AWS_REGION}
JAVA_OPTS=-Xmx512m -Xms256m
ENV

# Downloads the latest JAR; retries while IAM credentials / network settle.
# If S3 is unreachable but a JAR is already on disk, keep using that one.
cat > /usr/local/bin/fetch-app-jar.sh << 'SCRIPT'
#!/bin/bash
for i in $(seq 1 10); do
  if /usr/local/bin/aws s3 cp "s3://${S3_BUCKET}/${JAR_NAME}" "${APP_DIR}/${JAR_NAME}"; then
    chown ubuntu:ubuntu "${APP_DIR}/${JAR_NAME}"
    exit 0
  fi
  echo "JAR download failed (attempt $i), retrying..."
  sleep 10
done
[ -f "${APP_DIR}/${JAR_NAME}" ] && exit 0
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
User=ubuntu
WorkingDirectory=/opt/app
EnvironmentFile=/etc/default/springboot-app
ExecStart=/usr/bin/java $JAVA_OPTS -jar ${APP_DIR}/${JAR_NAME}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable springboot-app-fetch.service springboot-app.service
# If the JAR isn't in S3 yet (very first deploy), the app simply stays stopped until the workflow runs.
systemctl start springboot-app-fetch.service springboot-app.service || true
