# Base DNS of API Gateway
output "api_gateway_base_endpoint" {
  value = module.rest-api.api_gateway_endpoint
}

module "rest-api" {
  source = "../../../../modules/aws/apigateway"

  # Name of the api gateway 
  name = "my-api-gateway"

  # The type of apigateway to create. Can be either REGIONAL, EDGE, or PRIVATE. 
  # See https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-endpoint-types.html for more information.
  apigateway_type = "REGIONAL"

  stage_name = "v1"

  # A list of all the lambdas that will be used in the gateway. These same ARN 
  # values must also be pasted into their associated api_definition entry 
  # below.
  lambda_arns = [
    "arn:aws:lambda:us-east-1:906495541320:function:my_lambda_function"
    # "arn:aws:lambda:us-east-1:137067477747:function:some-lambda",
    # "arn:aws:lambda:us-east-1:137067477747:function:some-other-lambda"
  ]

  # The timeout (in milliseconds) for calls to the lambda
  api_gateway_timeout = 20000

  api_definition = [
    {
      http_verbs = ["GET"],
      url = "api/myresource", 
      authentication_required = true,
      lambda_arn = "arn:aws:lambda:us-east-1:906495541320:function:my_lambda_function",
      is_cors_required = true,
      use_default_cors = false
    }
    # },
    # {
    #   http_verbs = ["GET","DELETE"], 
    #   url = "api/users/{userName}",  # The curly braces are a path variable; query params are passed to lambda
    #   authentication_required = true, 
    #   lambda_arn = "arn:aws:lambda:us-east-1:137067477747:function:some-lambda"
    # },
    # {
    #   http_verbs = ["POST","PUT"],
    #   url = "api/users", 
    #   authentication_required = true,
    #   lambda_arn = "arn:aws:lambda:us-east-1:137067477747:function:some-other-lambda" 
    # },
  ]

  # The arn of an authorizer lambda to use to authorize requests to apis marked
  # 'authentication_required=true'.
  authorizer_lambda_arn = "arn:aws:lambda:us-east-1:906495541320:function:my_authorizer"

  # Already defaults to token, but here for clarity
  authorizer_type = "token"

  # Location of authorization token (in the request header as Authorization)
  authorizer_identity_source = "method.request.header.Authorization"

  # The TTL in seconds of cached authorizer results. If it equals 0, 
  # authorization caching is disabled. If it is greater than 0, 
  # apigateway will cache authorizer responses. If this field is not 
  # set, the default value is 300. The maximum value is 3600, or 1 hour.
  authorizer_result_cache_seconds = 60
  
  providers = {
    aws = aws.us-east-1
  }
}
