/*
 * An example of an event object can be seen here:
 * https://github.com/awsdocs/aws-lambda-developer-guide/blob/master/sample-apps/nodejs-apig/event.json
 * 
 */
exports.my_handler = async function(event, context) {
    return {
        "statusCode": 200,
        "headers": {
          "Content-Type": "application/json",
          "Access-Control-Allow-Headers" : "Content-Type",
          "Access-Control-Allow-Origin": "https://www.example.com",
          "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
        },
        "isBase64Encoded": false,
        "multiValueHeaders": { 
          "X-Custom-Header": ["My value", "My other value"],
        },
        "body": JSON.stringify({
          "resource": event.resource, 
          "httpMethod": event.httpMethod,
          "queryStringParameters": event.queryStringParameters,
          "domainName": event.requestContext.domainName,
          "apiId": event.requestContext.apiId,
        })
      }
}
