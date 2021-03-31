exports.my_authorizer = async function(event, context) {
    const token = event.authorizationToken.toLowerCase();

    const methodArn = event.methodArn; // Lambda to be invoked after authorizer is called

    switch(token) {
        case 'allow':
            return generateAuthResponse('user', 'Allow', methodArn);
        default:
            return generateAuthResponse('user', 'Deny', methodArn);
    }
}

function generateAuthResponse(principalId, effect, methodArn) {
    const policyDocument = generatePolicyDocument(effect, methodArn);

    return {
        principalId,
        policyDocument
    }
}

function generatePolicyDocument(effect, methodArn) {
    if (!effect || !methodArn) return null

    // Allows api-gateway to invoke lambda
    const policyDocument = {
        Version: '2012-10-17',
        Statement: [{
            Action: 'execute-api:Invoke',
            Effect: effect,
            Resource: methodArn
        }]
    }

    return policyDocument;
}