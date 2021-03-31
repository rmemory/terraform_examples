# Provides a settings of an API Gateway Account. Settings are applied 
# region-wide per provider block. In practice, it is just a global 
# setting for Cloudwatch monitoring for all apigateways. That said, 
# all logging & monitoring can be enabled/disabled and otherwise tuned 
# on the API Gateway Stage level. Hence, this is pretty much a copy and 
# paste from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account

# In all cases, applying this resource is required prior to deploying any
# apigateways.

# As there is no API method for deleting account settings or resetting 
# it to defaults, destroying this resource will keep your account settings 
# intact.

resource "aws_api_gateway_account" "this" {
  provider    = aws.us-east-1
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  provider    = aws.us-east-1
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  provider    = aws.us-east-1
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
