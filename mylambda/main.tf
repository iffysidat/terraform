provider "aws" {
    region = "eu-west-1"
}

resource "aws_lambda_function" "irfans_first_lambda" {
    function_name = "irfans-first-lambda"
    runtime       = "python3.7"
    handler       = "irfan_first_lambda.lambda_handler"
    filename      = "irfan_first_lambda.zip"
    role          = "${aws_iam_role.irfan_lambda_iam_role.arn}"
}

data "aws_iam_policy_document" "lambda_assumerole" {
  statement {
    sid    = "AllowLambdaAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "irfan_lambda_policy" {
  statement {
    sid    = "irfanLambdaPolicy"
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "irfan_lambda_iam_role" {
  name = "irfan_lambda_role"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assumerole.json}"
}

resource "aws_iam_policy" "irfan_lambda_first_policy" {
  name = "irfan_lambda_policy"

  policy = "${data.aws_iam_policy_document.irfan_lambda_policy.json}"
}

resource "aws_iam_role_policy_attachment" "irfan_policy_attachment" {
  role       = "${aws_iam_role.irfan_lambda_iam_role.name}"
  policy_arn = "${aws_iam_policy.irfan_lambda_first_policy.arn}"
}