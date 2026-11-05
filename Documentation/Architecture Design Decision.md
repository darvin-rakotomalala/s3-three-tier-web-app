# Architecture Design Decision of Scalable Three-Tier Web Application on AWS (Terraform)

> **Design Principles** : Reliability · Scalability · Performance · Security · Cost Optimization · Sustainability ·
> Operational · Excellence · Resilience

> **Scope** : Route 53 → CloudFront + WAF → S3 (frontend) / ALB → EC2 Auto Scaling (Spring Boot) → RDS PostgreSQL
> (backend)

## The Business Problem

***

## Architecture Objective

***

## Why Organizations Adopt This Architecture

***

## Major Business Benefits

***

## Typical Enterprise Scenarios

***

## Business Requirements

***

## Scalability Goals

***

## Availability Requirements

***

## Latency Requirements

***

## Security Expectations

***

## Expected Workload

***

## Expected Growth

***

## Architecture Overview

***

## Architecture Philosophy

***

## Core Components

***

## How Components Interact

***

## High-Level Workflow

***

## Request Lifecycle

***

## Response Lifecycle

***

## Data Lifecycle

***

---

## AWS Services Used

***

### Amazon EC2

### Application Load Balancer (ALB)

### Amazon CloudFront

### Amazon S3

### Amazon RDS

### Amazon SNS

### AWS IAM

### Amazon VPC

### Amazon Route 53

### Amazon CloudWatch

### AWS CloudTrail

### AWS KMS

### AWS Secrets Manager

### AWS Systems Manager

---

## Complete Architecture Diagram

***

---

## Component-by-Component Explanation

***

### Route 53

### CloudFront

### Application Load Balancer

### EC2 (Application Tier)

### RDS Multi-AZ

### SNS (Messaging Backbone)

### S3 (Static Assets & Data Lake)

### IAM, KMS, Secrets Manager (Security Layer)

### CloudTrail (Governance Layer)

### CloudWatch (Observability Layer)

## End-to-End Request Flow

***

---

## Deployment Flow

***

### Infrastructure Provisioning

### Terraform Workflow

### CI/CD Deployment

### Secrets

### Configuration

### Validation

---

## Network Topology

***

### VPC

### CIDR

### Public Subnets

### Private Subnets

### NAT Gateway

### Internet Gateway

### Transit Gateway

### Route Tables

### Network ACLs

### Security Groups

### PrivateLink

---

## Identity and Access

***

### IAM Roles

### IAM Policies

### Resource Policies

### STS

### Cross-Account Access

### Least Privilege

### Service Roles

### Permission Boundaries

---

## Security Architecture

***

### Encryption

### KMS

### TLS

### WAF

### Shield

### Secrets Manager

### Certificate Manager

### CloudTrail

### Zero Trust

### Threat Model

### Attack Vectors

### Mitigations

---

## High Availability

***






























