output "lambda_arn" {
  description = "The ARN of the lambda function"
  value       = module.lambda.lambda_arn
}

output "lambda_qualified_arn" {
  description = "The qualified ARN of the lambda function"
  value       = module.lambda.lambda_qualified_arn
}

module "lambda" {
  source = "../../../../modules/aws/lambda"

  function_name = "my_lambda_function"
  description= "This is a great lambda"

  filename = "./src/app.zip"
  handler = "main.my_handler"

  # The runtime to use for running the lambda
  runtime = "nodejs12.x"

  # If the role is specified above, this should be set to false
  create_default_role = true

  # Number of days to retain CloudWatch logs before they are deleted
  #log_retention_in_days = 90

  # Chose whether to enable CloudWatch lambda insights
  #is_cloudwatch_lambda_insights_enabled = false

  # The maximum time for the lambda to run
  #timeout_seconds = 120

  # The layer ARN's this lambda uses. Limited to five layers
  #layers = ["ALayerArn"]

  # Set to true if the lambda requires access to resources inside a VPC.
  #should_access_vpc = true

  # When the lambda uses a VPC, some attempt it made to figure out the proper
  # values for the VPC ID, subnet ids, and security_group_ids. But they can be
  # hardcoded here as well.
  #vpc_id = "vpc-xxxxxx"
  #private_subnet_ids = [ "subnet-xxxxx", "subnet-xxxxxxx" ]
  #security_group_ids = ["sg-xxxxxx"]

  # Environment Variables for the lambda
  # environment_variables = {
  #    "SOME_VAR" = "some value"
  #    "SOME_OTHER_VAR" = "some other value"
  # }

  # SQS Configuration

  # When using an SQS trigger for the lambda, set these ...
  #sqs_trigger = true
  #sqs_trigger_queue_arn = "TheQueueArn"

  # When using an SQS trigger, set the size of message batches to recieve
  #sqs_trigger_batch_size = 5

  # Kinesis Configuration

  # When using a Kinesis Data Stream trigger for the lambda, set these ...
  #kinesis_trigger = true
  #kinesis_trigger_arn = "TheKinesisArn"

  # Optional Kinesis details
  # The size of message batches to receive:
  #kinesis_trigger_batch_size = 5
  
  # Enable lambda to connect to Kinesis Shards concurrently:
  #kinesis_trigger_parallelization_factor = 10
  
  # Add a buffer of time to accumulate batch before calling the lambda:
  #kinesis_trigger_maximum_batching_window_in_seconds = 300
  
  # Kinesis Processing Mode (must be AT_TIMESTAMP, LATEST or TRIM_HORIZON)
  #kinesis_trigger_starting_position = "LATEST"
  
  # RFC3339 date format to use with AT_TIMESTAMP Processing Mode:
  #kinesis_trigger_starting_position_timestamp = "2019-10-12T07:20:50.52Z"
  
  # Set retry attempts on a Kinesis record before it is set to failed:
  #kinesis_trigger_maximum_retry_attempts = 3
  
  # Limit the age of records the lambda is allowed to process:
  #kinesis_trigger_maximum_record_age_in_seconds = 604800
  
  # When failures occur, the Kinesis batch is divided in two when true:
  #kinesis_trigger_bisect_batch_on_function_error = true
  
  # Set a failure destination (dead letter queue in SQS or SNS) when records fail:
  #kinesis_trigger_failure_destination_arn = "TheDeadLetterQueueOrSNSTopicARN"

  # Organization tags
  #org_tags = var.org_tags
  #billing_tag = var.billing_tag
  #other_tags = var.other_tags

  # Any terraform resources that this depends on
  #module_depends_on = [aws_key_pair.primary_key, aws_security_group.primary_sg]

  providers = {
    aws = aws.us-east-1
  }
}

