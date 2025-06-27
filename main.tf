provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "input_bucket" {
  bucket = "in-bucket-c"
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "out-bucket-c"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_translate_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_translate_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "translate:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "translate_lambda" {
  function_name = "translate_lambda"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "handler.lambda_handler"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.translate_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_bucket.arn
}

resource "aws_s3_bucket_notification" "trigger_lambda" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.translate_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

# module "translate_api_backend" {
#   source = "./modules/translate_api_backend"

#   input_bucket = aws_s3_bucket.input_bucket.bucket
# }