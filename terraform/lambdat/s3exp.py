import boto3
from botocore.exceptions import ClientError
import os 
S3_BUCKET = 'mbmar12'
AWS_ACCESS_KEY = 'AKIAWGV5G3EVZN6B4DJE'
AWS_SECRET_KEY = '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'
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)
sqs = boto3.client(
    'sqs', 
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)

def get_s3_object_head(bucket_name, object_key):
    # Initialize a boto3 S3 client
    # s3_client = boto3.client('s3')

    try:
        # Get the head of the S3 object
        response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
        
        # Return the metadata of the object
        return response

    except ClientError as e:
        # Handle error if the object doesn't exist or other S3 errors
        error_code = e.response['Error']['Code']
        if error_code == '404':
            print(f"Error: The object {object_key} does not exist in bucket {bucket_name}.")
        else:
            print(f"Error: {error_code}")
        return None

# Example usage:
bucket_name = 'mbmar12'  # Replace with your S3 bucket name
object_key = 'dz1.jpg'  # Replace with the S3 object key
object_metadata = get_s3_object_head(bucket_name, object_key)
if object_metadata:
    print("Object Metadata:", object_metadata)

print(' -------------------------------- ')
object_key = 'dz2.jpg'
object_metadata = get_s3_object_head(bucket_name, object_key)
if object_metadata:
    print("Object Metadata:", object_metadata)

print(' -------------------------------- ')
object_key = 'dz3.jpg'
object_metadata = get_s3_object_head(bucket_name, object_key)
if object_metadata:
    print("Object Metadata:", object_metadata)

print(' -------------------------------- ')
object_key = 'dz1 (1).jpg'
object_metadata = get_s3_object_head(bucket_name, object_key)
if object_metadata:
    print("Object Metadata:", object_metadata)