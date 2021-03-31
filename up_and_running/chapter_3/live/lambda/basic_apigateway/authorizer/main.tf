
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

  function_name = "my_authorizer"

  filename = "./src/app.zip"

  handler = "main.my_authorizer"

  runtime = "nodejs12.x"

  create_default_role = true

  providers = {
    aws = aws.us-east-1
  }
}

