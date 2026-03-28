# Serverless Hello World with AWS Lambda + API Gateway (Terraform)

Build a **super simple serverless API** using:

* 🐍 Python (AWS Lambda)
* 🌐 API Gateway (HTTP API)
* 🏗️ Terraform (Infrastructure as Code)

👉 Architecture:

```text
Client → API Gateway → Lambda → JSON Response
```

This guide walks you **from zero → deployed API → tested endpoint**.

---

## 🧱 Architecture Overview



---

## 📦 What You Will Build

A simple endpoint:

```bash
GET /hello
```

Returns:

```json
{
  "message": "Hello from Lambda!",
  "method": "GET",
  "path": "/hello"
}
```

---

## 🛠️ Prerequisites (Ubuntu)

### 1. Update system

```bash
sudo apt update && sudo apt upgrade -y
```

---

### 2. Install basic tools

```bash
sudo apt install -y curl unzip git
```

---

### 3. Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Verify:

```bash
aws --version
```

---

### 4. Configure AWS credentials

```bash
aws configure
```

You will need:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

Get them from:

👉 AWS Management Console
→ IAM → Users → Create Access Key

---

### 5. Install Terraform

```bash
sudo apt install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install terraform -y
```

Verify:

```bash
terraform -v
```

---

### 6. Verify AWS access

```bash
aws sts get-caller-identity
```

---

## 📁 Project Structure

```text
aws-simple-api/
├── main.tf
├── variables.tf
├── outputs.tf
└── lambda/
    └── app.py
```

---

## 🐍 Lambda Function (Python)

`lambda/app.py`

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

---

## ⚙️ Terraform Configuration

### variables.tf

```hcl
variable "aws_region" {
  default = "eu-west-2"
}

variable "project_name" {
  default = "simple-api-lambda"
}
```

---

### main.tf

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

---

### outputs.tf

```hcl
output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "hello_url" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/hello"
}
```

---

## 🚀 Deploy the Project

### 1. Initialize Terraform

```bash
terraform init
```

---

### 2. Plan

```bash
terraform plan
```

---

### 3. Apply

```bash
terraform apply
```

Type:

```bash
yes
```

---

## 🌍 Test the API

```bash
curl "$(terraform output -raw hello_url)"
```

Or open in browser:

```text
https://<your-api-id>.execute-api.eu-west-2.amazonaws.com/hello
```

---

## 🧹 Cleanup (IMPORTANT)

Avoid charges:

```bash
terraform destroy
```

---

## 🧠 Key Learnings

### 1. Serverless mindset

* No servers to manage
* Pay per request
* Auto scaling by default

---

### 2. API Gateway HTTP API vs REST API

* HTTP API → simpler, cheaper
* REST API → more features but heavier

---

### 3. Lambda proxy integration

Your Lambda must return:

```json
{
  "statusCode": 200,
  "headers": {},
  "body": "string"
}
```

---

### 4. Terraform workflow

```bash
init → plan → apply → destroy
```

---

### 5. IAM is critical

* Lambda needs execution role
* API Gateway needs permission to invoke Lambda

---

## ⚠️ Common Issues

### ❌ 502 Bad Gateway

👉 Lambda response format is wrong

---

### ❌ Permission denied

👉 Missing:

```hcl
aws_lambda_permission
```

---

### ❌ Terraform not detecting changes

👉 Ensure:

```hcl
source_code_hash
```

---

## 🔥 Next Improvements

You can extend this project with:

* POST endpoint
* Query parameters (`?name=Omid`)
* CORS support
* Custom domain
* CI/CD (GitHub Actions)
* S3 + DynamoDB integration
* Logging & monitoring (CloudWatch)

---

## 💡 Why This Matters

This tiny project teaches:

* real AWS architecture
* Infrastructure as Code (Terraform)
* serverless backend basics

👉 This is **exactly the kind of project recruiters love** for backend roles.

---

## ✍️ Author

**Omid Hashemzadeh**
Software Engineer
