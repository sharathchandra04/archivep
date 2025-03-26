import time
import boto3

# Initialize AWS Lambda client
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    # List of Lambda function names to trigger
    lambda_functions = ['LambdaFunctionName1', 'LambdaFunctionName2']  # Replace with your Lambda function names
    
    # Trigger the other Lambda functions every second for 55 seconds
    for _ in range(55):  # Loop for 55 seconds
        for lambda_name in lambda_functions:
            try:
                # Invoke each lambda function
                response = lambda_client.invoke(
                    FunctionName=lambda_name,
                    InvocationType='Event'  # Asynchronous invocation
                )
                print(f"Invoked {lambda_name} with response: {response}")
            except Exception as e:
                print(f"Error invoking {lambda_name}: {e}")
        
        # Sleep for 1 second before triggering again
        time.sleep(1)

    return {
        'statusCode': 200,
        'body': 'Successfully triggered Lambda functions every second for 55 seconds'
    }
