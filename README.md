# Serverless Hello World with AWS Lambda + API Gateway (Terraform)

Build a **super simple serverless API** using:

* 🐍 Python (AWS Lambda)
* 🌐 API Gateway (HTTP API)
* 🏗️ Terraform (Infrastructure as Code)

## Architecture

```text
Client → API Gateway → Lambda → JSON Response
```

This project is a beginner-friendly walkthrough that takes you from **local setup** to **deploying a live serverless API on AWS** using Terraform.

---

## Table of Contents

* [What You Will Build](#what-you-will-build)
* [Architecture Overview](#architecture-overview)
* [Prerequisites](#prerequisites)

  * [Linux(Ubuntu) Setup](#ubuntu-setup)
  * [Windows Setup](#windows-setup)
* [Project Structure](#project-structure)
* [Lambda Function](#lambda-function)
* [Terraform Configuration](#terraform-configuration)
* [How to Run the Project](#how-to-run-the-project)
* [Testing the API](#testing-the-api)
* [Cleanup](#cleanup)
* [What I Learned](#what-i-learned)
* [Common Issues](#common-issues)
* [Possible Improvements](#possible-improvements)
* [Why This Project Matters](#why-this-project-matters)
* [Author](#author)

---

## What You Will Build

A simple API endpoint:

```http
GET /hello
```

Expected response:

```json
{
  "message": "Hello from Lambda!",
  "method": "GET",
  "path": "/hello"
}
```

---

## Architecture Overview

This project uses the following flow:

1. A client sends a request to API Gateway
2. API Gateway forwards the request to AWS Lambda
3. The Lambda function runs Python code
4. Lambda returns a JSON response
5. API Gateway sends that response back to the client

This is one of the simplest real examples of a **serverless backend** on AWS.

---

## Prerequisites

Before running this project, you need:

* an AWS account
* AWS access keys
* AWS CLI
* Terraform
* Python 3
* Git
* unzip utility

---

## Linux(Ubuntu) Setup

### 1) Update your system

```bash
sudo apt update && sudo apt upgrade -y
```

### 2) Install basic tools

```bash
sudo apt install -y curl unzip git wget gnupg software-properties-common python3 python3-pip
```

### 3) Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Verify:

```bash
aws --version
```

### 4) Install Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
```

Verify:

```bash
terraform -v
```

### 5) Configure AWS CLI

```bash
aws configure
```

You will be asked for:

* `AWS Access Key ID`
* `AWS Secret Access Key`
* default region, for example: `eu-west-2`
* default output format, for example: `json`

### 6) Verify AWS access

```bash
aws sts get-caller-identity
```

If this works, your AWS CLI is configured correctly.

---

## Windows Setup

These steps use **PowerShell**.

### 1) Install Git

Download and install Git for Windows, then verify:

```powershell
git --version
```

### 2) Install Python

Download and install Python 3 from the official installer.

Important: during installation, tick **Add Python to PATH**.

Verify:

```powershell
python --version
```

### 3) Install AWS CLI

Download and install AWS CLI v2 for Windows.

After installation, verify:

```powershell
aws --version
```

### 4) Install Terraform

You have two common options.

#### Option A: Install with Chocolatey

If you already have Chocolatey:

```powershell
choco install terraform
```

Verify:

```powershell
terraform -v
```

#### Option B: Manual install

* Download the Terraform zip for Windows
* Extract `terraform.exe`
* Put it in a folder such as `C:\terraform`
* Add that folder to your system `PATH`

Then verify:

```powershell
terraform -v
```

### 5) Configure AWS CLI

```powershell
aws configure
```

Enter:

* `AWS Access Key ID`
* `AWS Secret Access Key`
* default region, for example: `eu-west-2`
* default output format, for example: `json`

### 6) Verify AWS access

```powershell
aws sts get-caller-identity
```

---

## Creating AWS Access Keys

To use AWS CLI and Terraform, you need programmatic credentials.

In the AWS Console:

1. Go to **IAM**
2. Go to **Users**
3. Create a new user or open an existing user
4. Create an **Access Key**
5. Copy:

   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`

For learning projects, many people use broad permissions, but in real projects it is better to use **least privilege**.

---

## Project Structure

```text
aws-simple-api/
├── main.tf
├── variables.tf
├── outputs.tf
└── lambda/
    └── app.py
```

---

## Lambda Function

File: `lambda/app.py`

```python
import json

def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "method": event.get("requestContext", {}).get("http", {}).get("method"),
            "path": event.get("rawPath")
        })
    }
```

This function receives the request event from API Gateway and returns a JSON response.

---

## Terraform Configuration

### `variables.tf`

```hcl
variable "aws_region" {
  default = "eu-west-2"
}

variable "project_name" {
  default = "simple-api-lambda"
}
```

### `main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/app.py"
  output_path = "${path.module}/lambda/app.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "hello" {
  function_name = "${var.project_name}-hello"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.12"
  handler       = "app.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.hello.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "hello" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
```

### `outputs.tf`

```hcl
output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "hello_url" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/hello"
}
```

---

## Optional `.gitignore`

A useful `.gitignore` for this project:

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl

# Lambda build artifacts
*.zip

# Python
__pycache__/
*.pyc

# Environment files
.env

# OS files
.DS_Store
Thumbs.db
```

---

## How to Run the Project

### 1) Clone the repository

```bash
git clone git@github.com:omidcodes/terraform-aws-lambda-api.git
cd terraform-aws-lambda-api
```

Or with HTTPS:

```bash
git clone https://github.com/omidcodes/terraform-aws-lambda-api.git
cd terraform-aws-lambda-api
```

### 2) Initialize Terraform

```bash
terraform init
```

### 3) Review the execution plan

```bash
terraform plan
```

### 4) Deploy the infrastructure

```bash
terraform apply
```

Type:

```text
yes
```

Terraform will create:

* an IAM role for Lambda
* the Lambda function
* an API Gateway HTTP API
* a route for `GET /hello`
* permission for API Gateway to invoke Lambda

---

## Testing the API

After deployment, get the endpoint:

```bash
terraform output -raw hello_url
```

Test with curl:

```bash
curl "$(terraform output -raw hello_url)"
```

Expected response:

```json
{
  "message": "Hello from Lambda!",
  "method": "GET",
  "path": "/hello"
}
```

You can also open the URL in your browser.

---

## Cleanup

To avoid unnecessary AWS charges, destroy the infrastructure when you are done:

```bash
terraform destroy
```

Type:

```text
yes
```

---

## What I Learned

This small project helped me understand several core cloud and backend concepts:

### 1) Serverless architecture

With AWS Lambda, there is no server to provision or manage manually. AWS runs the code only when a request arrives.

### 2) API Gateway as an HTTP front door

API Gateway exposes a public endpoint and forwards the request to Lambda.

### 3) Terraform for Infrastructure as Code

Instead of creating AWS resources manually in the console, Terraform lets us define infrastructure in code and recreate it reliably.

### 4) IAM permissions matter

Even for a tiny project, permissions are essential. Lambda needs an execution role, and API Gateway needs permission to invoke Lambda.

### 5) Deployment workflow

The Terraform workflow is simple and powerful:

```text
terraform init → terraform plan → terraform apply → terraform destroy
```

### 6) Lambda response format

When using Lambda proxy integration, the response must follow the expected structure:

```json
{
  "statusCode": 200,
  "headers": {},
  "body": "string"
}
```

---

## Common Issues

### `502 Bad Gateway`

Usually this means the Lambda response format is wrong.

Make sure your function returns:

* `statusCode`
* `headers`
* `body`

and that `body` is a string, usually JSON encoded with `json.dumps()`.

### `AccessDeniedException` or permission errors

Possible causes:

* incorrect AWS credentials
* insufficient IAM permissions
* missing `aws_lambda_permission`

### Terraform does not detect Lambda code changes

Make sure `source_code_hash` is included in the Lambda resource.

### `aws sts get-caller-identity` fails

Your AWS CLI credentials are probably incorrect or not configured yet.

### API deploys but endpoint does not work

Check:

* Lambda function exists
* API Gateway route exists
* API Gateway has permission to invoke Lambda
* region is correct
* Terraform apply completed successfully

---

## Possible Improvements

This project is intentionally minimal. Useful next steps include:

* add a `POST` endpoint
* accept query parameters such as `?name=Omid`
* enable CORS
* add structured logging
* set CloudWatch log retention
* integrate with DynamoDB or S3
* add GitHub Actions for CI/CD
* split Terraform into reusable modules
* use remote Terraform state

---

## Why This Project Matters

Although this is a small project, it demonstrates real backend and cloud engineering concepts:

* AWS Lambda
* API Gateway
* IAM
* Terraform
* Infrastructure as Code
* serverless API design

It is a strong beginner cloud project and a good portfolio piece for backend/software engineering roles.

---

## Author

**Omid Hashemzadeh**
Software Engineer