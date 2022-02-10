terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  profile = "craftsmen-dev"
  region  = var.aws_region
}

resource "aws_s3_bucket" "shohag_onboarding_test_bucket" {
  bucket = "shohag-onboarding-test-bucket"
  acl    = "private"

  tags = {
    Name        = "On-boarding Test Bucket"
    Environment = "Dev"
  }
}

resource "aws_iam_role" "shohag_onboard_iam_for_lambda" {
  name                  = "shohag_onboard_iam_for_lambda"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_event_consumer_lambda_policy" {
  name        = "s3_event_consumer_lambda_policy"
  description = "Log in cloudwath and invoke step function"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        "Resource" : [
          "arn:aws:logs:*:*:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "states:*",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.shohag_onboard_iam_for_lambda.name
  policy_arn = aws_iam_policy.s3_event_consumer_lambda_policy.arn
}

resource "aws_lambda_permission" "shohag_onboard_allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_event_consumer_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.shohag_onboarding_test_bucket.arn
}

resource "aws_lambda_function" "s3_event_consumer_lambda" {
  filename         = data.archive_file.s3_event_consumer_lambda_archive.output_path
  function_name    = "s3_event_consumer_lambda"
  source_code_hash = data.archive_file.s3_event_consumer_lambda_archive.output_base64sha256
  role             = aws_iam_role.shohag_onboard_iam_for_lambda.arn
  handler          = "s3_event_consumer.handler"
  runtime          = "python3.7"
  architectures    = ["x86_64"]
  timeout          = 15
  environment {
    variables = {
      "REGION"       = var.aws_region
      "STEP_FN_NAME" = data.aws_sfn_state_machine.state_machine_data.name
      "STEP_FN_ARN"  = data.aws_sfn_state_machine.state_machine_data.arn
    }
  }
  depends_on = [aws_sfn_state_machine.shohag_onboarding_test_step_fnc]
}

resource "aws_s3_bucket_notification" "shohag_onboard_bucket_notification" {
  bucket = aws_s3_bucket.shohag_onboarding_test_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_event_consumer_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.shohag_onboard_allow_bucket]
}

resource "aws_cloudwatch_log_group" "s3_event_consumer_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.s3_event_consumer_lambda.function_name}"
  retention_in_days = 1
}

resource "aws_dynamodb_table" "shohag_onboarding_test_table" {
  name           = var.file_summary_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "file_type"

  attribute {
    name = "file_type"
    type = "S"
  }

  tags = {
    Name        = var.file_summary_table_name
    Environment = "Test Table"
  }
}

resource "aws_iam_role" "shohag_onboard_iam_for_stepfn_lambda" {
  name                  = "shohag_onboard_iam_for_stepfn_lambda"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "step_fn_lambda_policy" {
  name        = "step_fn_lambda_policy"
  description = "Log in cloudwath"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        "Resource" : [
          "arn:aws:logs:*:*:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : "${aws_dynamodb_table.shohag_onboarding_test_table.arn}"
      }
      # {
      #   "Sid" : "AllowPublishToMyTopic",
      #   "Effect" : "Allow",
      #   "Action" : "sns:Publish",
      #   "Resource" : [
      #     "${aws_sns_topic.file_summary_topic.arn}"
      #   ]
      # }
    ]
  })
  depends_on = [
    aws_dynamodb_table.shohag_onboarding_test_table
  ]
}

resource "aws_iam_role_policy_attachment" "step_fn_lambda_policy_attachment" {
  role       = aws_iam_role.shohag_onboard_iam_for_stepfn_lambda.name
  policy_arn = aws_iam_policy.step_fn_lambda_policy.arn
}

resource "aws_lambda_function" "s3_object_counter_lambda" {
  filename         = data.archive_file.s3_object_counter_lambda_archive.output_path
  function_name    = "s3_object_counter_lambda"
  source_code_hash = data.archive_file.s3_object_counter_lambda_archive.output_base64sha256
  role             = aws_iam_role.shohag_onboard_iam_for_stepfn_lambda.arn
  handler          = "s3_object_counter.handler"
  runtime          = "python3.7"
  architectures    = ["x86_64"]
  environment {
    variables = {
      "REGION"     = var.aws_region
      "TABLE_NAME" = var.file_summary_table_name
    }
  }
}

resource "aws_lambda_function" "s3_object_size_calculator_lambda" {
  filename         = data.archive_file.s3_object_size_calculator_lambda_archive.output_path
  function_name    = "s3_object_size_calculator_lambda"
  source_code_hash = data.archive_file.s3_object_size_calculator_lambda_archive.output_base64sha256
  role             = aws_iam_role.shohag_onboard_iam_for_stepfn_lambda.arn
  handler          = "s3_object_size_calculator.handler"
  runtime          = "python3.7"
  architectures    = ["x86_64"]
  environment {
    variables = {
      "REGION"     = var.aws_region
      "TABLE_NAME" = var.file_summary_table_name
    }
  }
}

resource "aws_cloudwatch_log_group" "step_fn_object_counter_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.s3_object_counter_lambda.function_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "step_fn_object_size_calculator_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.s3_object_size_calculator_lambda.function_name}"
  retention_in_days = 1
}

resource "aws_sns_topic" "file_summary_topic" {
  name = "file_summary_topic"
}

resource "aws_iam_role" "shohag_onboard_iam_for_step_fnc" {
  name                  = "shohag_onboard_iam_for_step_fnc"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "step_function_lambda_invoke_policy" {
  name        = "step_function_lambda_invoke_policy"
  description = "Invoke Lambda"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction",
          "lambda:InvokeAsync",

        ],
        "Resource" : [
          "${aws_lambda_function.s3_object_counter_lambda.arn}",
          "${aws_lambda_function.s3_object_size_calculator_lambda.arn}",
        ]
      },
      {
        "Sid" : "AllowPublishToMyTopic",
        "Effect" : "Allow",
        "Action" : "sns:Publish",
        "Resource" : [
          "${aws_sns_topic.file_summary_topic.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_fn_lambda_policy" {
  role       = aws_iam_role.shohag_onboard_iam_for_step_fnc.name
  policy_arn = aws_iam_policy.step_function_lambda_invoke_policy.arn
}

resource "aws_sfn_state_machine" "shohag_onboarding_test_step_fnc" {
  name     = "shohag-onboarding-state-machine"
  role_arn = aws_iam_role.shohag_onboard_iam_for_step_fnc.arn

  definition = jsonencode({
    "Comment" : "A Hello World example of the Amazon States Language using an AWS Lambda Function",
    "StartAt" : "ObjectCounter",
    "States" : {
      "ObjectCounter" : {
        "Type" : "Task",
        "Resource" : "${aws_lambda_function.s3_object_counter_lambda.arn}",
        "Next" : "SizeCalculator"
      },
      "SizeCalculator" : {
        "Type" : "Task",
        "Resource" : "${aws_lambda_function.s3_object_size_calculator_lambda.arn}",
        "Next" : "PublishTopic"
      },
      "PublishTopic" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::sns:publish",
        "Parameters" : {
          "TopicArn" : "${aws_sns_topic.file_summary_topic.arn}",
          "Message" : {
            "Input.$" : "$",
          }
        },
        "End" : true
      }
    }
  })
}

