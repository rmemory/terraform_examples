
module "lambda" {
  source = "../../../../modules/aws/lambda"

  function_name = "my_cloudatch_triggered_lambda"
  description= "This lambda is triggered by a Cloudwatch event"

  filename = "./src/app.zip"
  handler = "app.handler"
  runtime = "nodejs12.x"

  create_default_role = true
  can_access_vpc = true
}

# Add ability for the lambda to call the secrets manager to role
resource "aws_iam_role_policy_attachment" "attach-secrets-manager" {
  role       = module.lambda.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  depends_on = [module.lambda]
}

# Add the ability for the lambda to add custom metrics to cloudwatch
resource "aws_iam_policy" "lambda_cloudwatch_custom_metrics" {
  name        = "Lambda_CloudWatch_Custom_Metrics"
  path        = "/"
  description = "CloudWatch custom metrics policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_cloudwatch_custom_metrics" {
  role       = module.lambda.lambda_role_name
  policy_arn = aws_iam_policy.lambda_cloudwatch_custom_metrics.arn
  depends_on = [module.lambda]
}

# Cause cloudwatch to trigger the lambda every 30 minutes
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "CloudWatch trigger schedule"
  description         = "Run every 30 minutes"
  schedule_expression = "rate(30 minutes)"
}

# Allow cloudwatch to call the lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "my-cloud-watch-event"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
  depends_on = [module.lambda]
}

# Provides an EventBridge Target resource.
# A target is a resource that is invoked when a rule is triggered. 
# In this case, the target is the Lambda. The trigger is CloudWatch.
# See https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-targets.html
resource "aws_cloudwatch_event_target" "my-scheduled-rule-target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  arn       = module.lambda.lambda_arn
  depends_on = [aws_lambda_permission.allow_cloudwatch]
}

resource "aws_sns_topic" "this" {
  name = "rds-users-poller-sns-topic-11b016"
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name                = "my-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "UsersWithoutCmisPreferredName"
  dimensions                = { "CustomMetrics"  = "UsersMissingName" }
  namespace                 = "Recovery"
  period                    = "1800"
  statistic                 = "Sum"
  threshold                 = "37"
  alarm_description         = "Notify when there are more than 37 leaders with missing cmiss preferred names"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.this.arn]
  treat_missing_data        = "notBreaching"
  depends_on = [aws_sns_topic.this]
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.emails) # create one aws_sns_topic_subscription per email
  endpoint  = each.value

  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  depends_on = [aws_sns_topic.this]
}

resource "aws_sns_topic_subscription" "sms" {
  for_each = toset(var.sms_phone_numbers) # create one aws_sns_topic_subscription per phone number
  endpoint  = each.value

  topic_arn = aws_sns_topic.this.arn
  protocol  = "sms"
  depends_on = [aws_sns_topic.this]
}
