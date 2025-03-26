import boto3
import logging
import json
from botocore.exceptions import ClientError

dynamodb = boto3.client('dynamodb')
s3 = boto3.client('s3')

DYNAMODB_TABLE = 'myassets'
SOURCE_BUCKET = 'rscmainb'
DEST_BUCKET = 'rscarchiveb'


import boto3
from botocore.exceptions import ClientError

def send_email(to_email, subject, body, pk, sk):
    ses = boto3.client('ses')
    try:
        response = ses.send_email(
            Source='rajasharathchandraacha@gmail.com',
            Destination={'ToAddresses': [to_email]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body}}
            }
        )
        print("Email sent! Message ID:", response['MessageId'])
        table = dynamodb.Table('folders')
        response = table.update_item(
            Key={
                'partition_key': pk,
                'sort_key': sk
            },
            UpdateExpression='SET isarchived = :true',
            ExpressionAttributeValues={
                ':true': False
            },
            ReturnValues='UPDATED_NEW'
        )
        logging.info(f"Updated archived_assets and isarchived for {pk}, {sk}")
    except Exception as e:
        logging.error(f"Error updating DynamoDB: {str(e)}")
    except ClientError as e:
        print(f"Error sending email: {e.response['Error']['Message']}")

def update_archived_assets(table_name, partition_key, sort_key, email):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)
    
    try:
        response = table.update_item(
            Key={
                'partition_key': partition_key,
                'sort_key': sort_key
            },
            UpdateExpression='SET archived_assets = archived_assets - :val',
            ConditionExpression='archived_assets > :zero',
            ExpressionAttributeValues={
                ':val': 1,
                ':zero': 0
            },
            ReturnValues='UPDATED_NEW'
        )
        updated_value = response['Attributes'].get('archived_assets', None)
        
        if updated_value == 0:
            send_email(
                email, 
                "Archived Assets Depleted", 
                f"The archived assets for folder {partition_key} have reached zero.",
                partition_key,
                sort_key
            )
        
        return response['Attributes']
    except ClientError as e:
        print(f"Error updating item: {e.response['Error']['Message']}")
        return None

# Example usage
# if __name__ == "__main__":
#     table_name = 'YourDynamoDBTable'
#     partition_key = 'Folder123'
#     sort_key = 'SomeSortKey'
    
#     updated_attributes = update_archived_assets(table_name, partition_key, sort_key)
#     if updated_attributes:
#         print("Updated Record:", updated_attributes)
#     else:
#         print("Failed to update record.")

def lambda_handler(event, context):
    try:
        response = dynamodb.scan(
            TableName=DYNAMODB_TABLE,
            FilterExpression="restore_initiated = :val",
            ExpressionAttributeValues={":val": {"BOOL": True}},
            Limit=1  # Fetch only 10 records at a time
        )
        
        if 'Items' not in response or len(response['Items']) == 0:
            return {
                'statusCode': 200,
                'body': json.dumps("No records to check or restore.")
            }

        # Process each record
        for item in response['Items']:
            record_id = item['record_id']['S']
            object_key = item['path']['S']  # The object path (S3 key)
            userid = item['user']['I']
            foldername = item['folder']['S']
            usermail = item['email']['S']

            # Step 2: Get the metadata (head) of the object in the source S3 bucket
            try:
                head_response = s3.head_object(
                    Bucket=SOURCE_BUCKET,
                    Key=object_key
                )
                
                # Step 3: Check if the object is restored (Restore field)
                restore_status = head_response.get('Restore', None)

                if restore_status is None:
                    # If restore status is None, update the DynamoDB record to set restore_initiated to False
                    logging.info(f"Object {object_key} is not in restoration or is missing the 'Restore' field.")
                    # Update DynamoDB record
                    dynamodb.update_item(
                        TableName=DYNAMODB_TABLE,
                        Key={'record_id': {'S': record_id}},
                        UpdateExpression="SET restore_initiated = :val",
                        ExpressionAttributeValues={":val": {"BOOL": False}}
                    )
                    logging.info(f"Updated 'restore_initiated' to False for record {record_id} in DynamoDB.")
                    continue  # Skip processing further for this record
                
                # Step 4: Check the restore status (if the restore is complete)
                if "ongoing-request=\"true\"" in restore_status:
                    logging.info(f"Object {object_key} is still being restored. Skipping.")
                    continue  # Restore is still in progress, do nothing
                
                if "ongoing-request=\"false\"" in restore_status:
                    # Step 5: Object is restored, delete the record from DynamoDB and copy the object to the destination bucket
                    
                    # Delete the record from DynamoDB
                    dynamodb.delete_item(
                        TableName=DYNAMODB_TABLE,
                        Key={'record_id': {'S': record_id}}
                    )
                    logging.info(f"Record with ID {record_id} deleted from DynamoDB.")
                    
                    # Step 6: Copy the object from the source bucket to the destination bucket as a standard class
                    copy_response = s3.copy_object(
                        CopySource={'Bucket': SOURCE_BUCKET, 'Key': object_key},
                        Bucket=DEST_BUCKET,
                        Key=object_key,
                        StorageClass='STANDARD'
                    )
                    logging.info(f"Object {object_key} successfully copied to {DEST_BUCKET} as STANDARD class.")
                    updated_attributes = update_archived_assets('folders', userid, foldername, usermail)
                    if updated_attributes:
                        print("Updated Record:", updated_attributes)
                    else:
                        print("Failed to update record.")

            except ClientError as e:
                logging.error(f"Error accessing S3 object {object_key}: {e}")
                continue  # Skip this object if there's an error

        return {
            'statusCode': 200,
            'body': json.dumps("Lambda execution completed successfully.")
        }
    
    except Exception as e:
        logging.error(f"Error during Lambda execution: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error during Lambda execution: {str(e)}")
        }
