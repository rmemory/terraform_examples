This provides a very simple example of deploying and using a lamba via apigateway, which also includes a trivial (not real world) authorizer.

The first step is to take a look at the source code inside of hello_world/src/main.js. If it already does what you want, you are ready to go, no further changes to the code required. If you do choose to update the code, run `make` in that same directory to update app.zip. The code in that zip file will be deployed to the lambda.

Next, run `terraform apply` for both the `hello_world` and `authorizer` lambas. Both will print out the ARNs for each lambda. These strings will need to be pasted into their desginated variables inside of apigateway/main.tf. 

Next, run `terraform apply` in the `apigateway_account` directory. 

Last, cd into the `apigateway` directory. After you have copied the lambda ARNs into their proper locations inside of main.tf (as mentioned above), plus any other adjustments you wish to make for the apigateway configuration, run `terraform apply`. It will print out the base endpoint url to access the apigateway. For example,

https://21d2tcxf0g.execute-api.us-east-1.amazonaws.com/v1

Apply the rest of the string to complete the endpoint url based on your own api_definition. For example, 

https://21d2tcxf0g.execute-api.us-east-1.amazonaws.com/v1/api/myresource

Paste that URL into an HTTP client of your choosing (for example, Postman). If you access the endpoint as-is without any additional modifications to the headers, you should see it fail because the Authorization token must be provided.

Add `Authorization` to the header, and assign it a value of `allow`. In the real world, the value might contain something like a JWT token which would then be validated by the authorizer lambda.

With that Authorization token in place in the header, you should receive a valid response. Note that any query params you add will also be passed along to the Lambda.

# Future enhancments 

Implement a top level makefile which uses `sed` to build everything from a single command.