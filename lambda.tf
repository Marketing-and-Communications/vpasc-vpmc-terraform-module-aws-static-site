resource "aws_iam_role" "iam_for_lambda" {
  name = "iam-for-lambda-edge-${var.deployment}"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
          },
          Effect = "Allow"
          Sid    = "AssumeRole"
        }
      ]
  })
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role_${var.deployment}"
  path        = "/cloudfront/lambda/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "arn:aws:logs:*:*:*"
          Effect   = "Allow"
        }
      ]
  })
}

resource "aws_cloudwatch_log_group" "rewrite_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.edge_rewrite.function_name}"
  retention_in_days = var.log_expiration
}

resource "aws_cloudwatch_log_group" "security_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.edge_security.function_name}"
  retention_in_days = var.log_expiration
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}


resource "aws_lambda_function" "edge_rewrite" {
  filename = data.archive_file.zip_edge_rewrite.output_path
  function_name = "LambdaEdgeRewriteFunction-${var.deployment}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  publish       = true

  source_code_hash = data.archive_file.zip_edge_rewrite.output_base64sha256

  runtime = "nodejs${var.lambda_runtime}.x"
}

resource "aws_lambda_function" "edge_security" {
  filename = data.archive_file.zip_edge_security.output_path
  function_name = "LambdaEdgeSecurityFunction-${var.deployment}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  publish       = true

  source_code_hash = data.archive_file.zip_edge_security.output_base64sha256

  runtime = "nodejs${var.lambda_runtime}.x"

}

# Vendor the dependencies
data "external" "rewrite_lambda_dependencies" {
  program = ["bash", "-c", <<EOT
(cd ${path.module}/LambdaEdgeFunctions/rewrite && LAMBDA_FUNCTION_NAME=rewrite \
  LAMBDA_RUNTIME=${var.lambda_runtime} docker compose up; docker compose down) >&2 > /tmp/rewrite.log && \
echo "{\"target_dir\": \"${path.module}/LambdaEdgeFunctions/rewrite\"}"
EOT
  ]
}

# Vendor the dependencies
data "external" "security_lambda_dependencies" {
  program = ["bash", "-c", <<EOT
(cd ${path.module}/LambdaEdgeFunctions/security && LAMBDA_FUNCTION_NAME=security \
  LAMBDA_RUNTIME=${var.lambda_runtime} docker compose up; docker compose down) >&2 > /tmp/security.log && \
echo "{\"target_dir\": \"${path.module}/LambdaEdgeFunctions/security\"}"
EOT
  ]
}

# The output_file_mode makes this zip file deterministic across environments
data "archive_file" "zip_edge_rewrite" {
  type             = "zip"
  source_dir       = data.external.rewrite_lambda_dependencies.result.target_dir
  output_path      = "${path.module}/LambdaEdgeRewriteFunction.zip"
  output_file_mode = "0666"
}

# The output_file_mode makes this zip file deterministic across environments
data "archive_file" "zip_edge_security" {
  type             = "zip"
  source_dir       = data.external.security_lambda_dependencies.result.target_dir
  output_path      = "${path.module}/LambdaEdgeSecurityFunction.zip"
  output_file_mode = "0666"
}



# This was moved to lambda.tf so that localstack could use that file independently
variable "lambda_runtime" {
  type        = number
  description = "The node.js runtime version to use for the lambda@edge function"
  default     = 16
}
