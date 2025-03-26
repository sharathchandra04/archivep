import boto3
import logging
import json
from botocore.exceptions import ClientError
from datetime import datetime

# Initialize boto3 clients for DynamoDB and S3
dynamodb = boto3.client('dynamodb')
s3 = boto3.client('s3')

# Your DynamoDB table name
DYNAMODB_TABLE = 'myassets'  # Replace with your DynamoDB table name
S3_BUCKET = 'rscarchiveb'  # Replace with your S3 bucket name

def lambda_handler(event, context):
    try:
        # Scan the DynamoDB table for records where 'restore_initiated' is False
        response = dynamodb.scan(
            TableName=DYNAMODB_TABLE,
            FilterExpression="restore_initiated = :val",
            ExpressionAttributeValues={":val": {"BOOL": False}}
        )
        
        if 'Items' not in response or len(response['Items']) == 0:
            return {
                'statusCode': 200,
                'body': json.dumps("No records to restore.")
            }

        # Sort by 'last_inserted' to ensure first-come, first-served order
        items = sorted(response['Items'], key=lambda x: x['last_inserted']['S'])

        # Process each record
        for item in items:
            record_id = item['record_id']['S']
            # object_key = item['path']['S']  # The object path in the S3 bucket
            
            # Step 1: Initiate Restore for the object in S3 Glacier or Deep Archive
            try:
                # Initiate the restore for the object in Glacier or Deep Archive
                restore_response = s3.restore_object(
                    Bucket=S3_BUCKET,
                    Key=object_key,
                    RestoreRequest={
                        'Days': 1,  # Restore for 1 day
                        'GlacierJobParameters': {
                            'Tier': 'Standard'  # You can choose 'Bulk' or 'Standard' based on your need
                        }
                    }
                )
                
                logging.info(f"Restore initiated for {object_key} in {S3_BUCKET}. Response: {restore_response}")
                
                # Step 2: Update the 'restore_initiated' field in DynamoDB
                update_response = dynamodb.update_item(
                    TableName=DYNAMODB_TABLE,
                    Key={
                        'path': {'S': object_key}
                    },
                    UpdateExpression="SET restore_initiated = :val",
                    ExpressionAttributeValues={":val": {"BOOL": True}},
                    ReturnValues="UPDATED_NEW"
                )
                
                logging.info(f"Record {record_id} updated with restore_initiated=True")
                
            except ClientError as e:
                logging.error(f"Error restoring object {object_key}: {str(e)}")
                continue  # Skip the current item and process the next one
            
        return {
            'statusCode': 200,
            'body': json.dumps("Restoration process completed successfully.")
        }

    except ClientError as e:
        logging.error(f"Error scanning DynamoDB table: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }
