const AWS = require('aws-sdk');
const lambda = new AWS.Lambda({apiVersion: '2015-03-31'});

exports.handler = async (event) => {
    const { functionName, concurrency, delay } = event;
    const param = {
            FunctionName: functionName,
            InvocationType: "Event",
            Payload: new Buffer(JSON.stringify({
                'warmer': true,
                'delay': delay
            }))
        };
    let invoke_list = [];

    for (let i=1; i<concurrency; i++) {
        invoke_list.push(lambda.invoke(param).promise())
    }
    const start = Date.now()
    Promise.all(invoke_list).then((res) => {
      console.log(`elpased time : ${Date.now() - start}ms`);
      console.log("It completes invoking all lambdas asynchronously.")
    })

    let result = await lambda.invoke({
        FunctionName: functionName,
        InvocationType: "RequestResponse",
        Payload: new Buffer(JSON.stringify({
            'warmer': true,
            'delay': delay
        }))
    }).promise();

    return result
};