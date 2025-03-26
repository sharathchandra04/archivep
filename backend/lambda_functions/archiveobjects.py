import boto3
import json
import logging
import os
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def update_archived_assets(table_name, partition_key, sort_key):
    table = dynamodb.Table(table_name)
    try:
        response = table.update_item(
            Key={
                'partition_key': partition_key,
                'sort_key': sort_key
            },
            UpdateExpression='SET archived_assets = archived_assets + :val',
            ExpressionAttributeValues={
                ':val': 1
            },
            ReturnValues='UPDATED_NEW'
        )
        logging.info(f"Updated archived_assets for {partition_key}, {sort_key}")
    except Exception as e:
        logging.error(f"Error updating DynamoDB: {str(e)}")

def lambda_handler(event, context):
    try:
        for record in event['Records']:
            object_path = record['body']
            source_bucket = os.environ['BUCKET_SRC']
            destination_bucket = os.environ['BUCKET_DEST']
            table_name = 'folders'
            parts = object_path.split('/')
            partition_key = parts[0]
            sort_key = parts[1]
            copy_source = {
                'Bucket': source_bucket,
                'Key': object_path
            }
            print('object_path --> ', object_path)
            
            response = s3.copy_object(
                CopySource=copy_source,
                Bucket=destination_bucket,
                Key=object_path,
                StorageClass='DEEP_ARCHIVE'
            )
            
            delete_response = s3.delete_object(
                Bucket=source_bucket,
                Key=object_path
            )
            logging.info(f"Successfully moved {object_path} from {source_bucket} to {destination_bucket} with DEEP_ARCHIVE storage class.")
            # Update DynamoDB table
            update_archived_assets(table_name, partition_key, sort_key)   
            return {
                'statusCode': 200,
                'body': json.dumps(f"Successfully copied {object_path} and updated DynamoDB.")
            }
    
    except Exception as e:
        logging.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }