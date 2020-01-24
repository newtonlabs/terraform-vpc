data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "testSSL"
  role             = aws_iam_role.iam_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"

  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.private.id]
  }
}

# Policies

# Assume role document
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Role defintion
resource "aws_iam_role" "iam_lambda" {
  name               = "iam_lambda"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy.json
}

# Network policy document (For inner VPC work)
data "aws_iam_policy_document" "network" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]

    resources = [
      "*",
    ]
  }
}

# Network policy
resource "aws_iam_policy" "network" {
  name   = "lambda_network"
  policy = data.aws_iam_policy_document.network.json
}

# Attach to lambda role
resource "aws_iam_policy_attachment" "network" {
  name       = "lambda_network"
  roles      = [aws_iam_role.iam_lambda.name]
  policy_arn = aws_iam_policy.network.arn
}