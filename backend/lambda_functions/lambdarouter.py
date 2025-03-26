import boto3
import json

# Initialize boto3 clients
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    # Loop through each SQS record (message)
    for record in event['Records']:
        # Get the message body from SQS
        message_body = json.loads(record['body'])  # Assuming JSON message body

        # Extract event type from the message body
        event_type = message_body.get('event_type')

        # Based on the event type, route the message to the appropriate Lambda function
        if event_type == 'eventTypeA':
            # Invoke LambdaFunctionA
            response = lambda_client.invoke(
                FunctionName='LambdaFunctionA',
                InvocationType='Event',  # Asynchronous invocation
                Payload=json.dumps(message_body)
            )
            print(f"Invoked LambdaFunctionA with response: {response}")

        elif event_type == 'eventTypeB':
            # Invoke LambdaFunctionB
            response = lambda_client.invoke(
                FunctionName='LambdaFunctionB',
                InvocationType='Event',
                Payload=json.dumps(message_body)
            )
            print(f"Invoked LambdaFunctionB with response: {response}")

        elif event_type == 'eventTypeC':
            # Invoke LambdaFunctionC
            response = lambda_client.invoke(
                FunctionName='LambdaFunctionC',
                InvocationType='Event',
                Payload=json.dumps(message_body)
            )
            print(f"Invoked LambdaFunctionC with response: {response}")

        else:
            print("No matching event type found")

    return {
        'statusCode': 200,
        'body': json.dumps('Message routing completed successfully')
    }
