data "archive_file" "s3_event_consumer_lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/lambdas/s3_event_consumer.py"
  output_path = "${path.module}/lambdas/s3_event_consumer.zip"
}

data "archive_file" "s3_object_counter_lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/lambdas/s3_object_counter.py"
  output_path = "${path.module}/lambdas/s3_object_counter.zip"
}

data "archive_file" "s3_object_size_calculator_lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/lambdas/s3_object_size_calculator.py"
  output_path = "${path.module}/lambdas/s3_object_size_calculator.zip"
}
data "aws_sfn_state_machine" "state_machine_data" {
  name = "shohag-onboarding-state-machine"
}