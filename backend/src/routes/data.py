from flask import Blueprint
from flask import Flask, jsonify, request, make_response
from flask_jwt_extended import JWTManager, create_access_token, jwt_required
from flask_jwt_extended import get_jwt_identity
from ..db.models import User, Folder
from src import bcrypt, csrf
from ..db import db
from flask import current_app
from werkzeug.utils import secure_filename
import os
import boto3
from botocore.exceptions import ClientError

data_bp = Blueprint('data', __name__)
S3_BUCKET = os.getenv('S3_BUCKET')  # Set your S3 bucket name in environment variables
S3_BUCKET_DEST = os.getenv('S3_BUCKET_DEST')
AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY')  # Set your AWS Access Key in environment variables
AWS_SECRET_KEY = os.getenv('AWS_SECRET_KEY')  # Set your AWS Secret Key in environment variables
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')  # Default AWS region (change as needed)
AWS_DYNAMODB_TABLE = os.getenv('AWS_DYNAMO_DB', 'myassets')  # Default AWS region (change as needed)
AWS_QUEUE_URL = os.getenv('AWS_QUEUE_URL', "https://sqs.us-east-1.amazonaws.com/426672314667/archiveassets")

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

dynamodb = boto3.resource(
    'dynamodb',
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY, 
    region_name='us-east-1'
)
table = dynamodb.Table(AWS_DYNAMODB_TABLE)
def insert_multiple_items(items):
    print(' --> ', items)
    try:
        with table.batch_writer() as batch:
            for item in items:
                print('$$', item)
                batch.put_item(Item=item)
                print(f"Item inserted: {item}")
        print("All items inserted successfully.")
    except ClientError as e:
        print(f"Error inserting items: {e}")

def get_signed_url(key):
    """Generate a signed URL for accessing an S3 object."""
    return s3_client.generate_presigned_url(
        "get_object",
        Params={"Bucket": S3_BUCKET, "Key": key},
        ExpiresIn=3600  # 1 hour expiry
    )

@data_bp.route("/get_images", methods=["GET"])
def get_images():
    BUCKET_NAME = S3_BUCKET
    """Fetch images from S3 with pagination."""
    try:
        page = int(request.args.get("page", 1))
        limit = int(request.args.get("limit", 2))
        response = s3_client.list_objects_v2(Bucket=BUCKET_NAME)
        if "Contents" not in response:
            return jsonify({"message": "No images found"}), 404
        all_files = [obj["Key"] for obj in response["Contents"]]
        start_index = (page - 1) * limit
        end_index = start_index + limit
        paginated_files = all_files[start_index:end_index]
        signed_urls = [get_signed_url(key) for key in paginated_files]
        return jsonify({"images": signed_urls, "page": page, "limit": limit, "total_images": len(all_files)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@data_bp.route('/restore', methods=['POST'])
@jwt_required()
def restore_objs():
    folder_name = request.json.get('name')
    current_user = get_jwt_identity()
    files = list_files_in_s3(S3_BUCKET_DEST, f"{current_user}/{folder_name}")
    items = [{'id': f, 'key': f, 'user': current_user, 'folder': folder_name, 'restore_initiated': False} for f in files]
    print(files)
    insert_multiple_items(items)
    return jsonify(logged_in_as=current_user), 200

def upload_file_to_s3(file, path, user):
    filename = secure_filename(file.filename)
    try:
        s3_client.upload_fileobj(file, S3_BUCKET, f"{user}/{path}/{filename}")
        file_url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{user}/{path}/{filename}"
        return file_url
    except Exception as e:
        print(f"Error uploading to S3: {e}")
        return None

@data_bp.route('/upload', methods=['POST'])
@jwt_required()
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    folder = request.form.get("folder")
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    current_user = get_jwt_identity()
    file_url = upload_file_to_s3(file, folder, current_user)
    if file_url:
        return jsonify({'message': 'File uploaded successfully', 'url': file_url}), 200
    else:
        return jsonify({'error': 'Failed to upload file'}), 500

def list_files_in_s3(bucket, prefix=""):
    try:
        response = s3_client.list_objects_v2(Bucket=bucket, Prefix=prefix)
        if 'Contents' in response:
            files = [obj['Key'] for obj in response['Contents']]
            return files
        else:
            print("No files found.")
            return []
    except Exception as e:
        print(f"Error retrieving files: {str(e)}")
        return []

@data_bp.route('/archive', methods=['POST'])
@jwt_required()
def archive():
    folder_name = request.json.get('name')
    current_user = get_jwt_identity()
    files = list_files_in_s3(S3_BUCKET, f"{current_user}/{folder_name}")
    print(files)
    for f in files:
        message_body = f"{f}"
        response = sqs.send_message(
            QueueUrl=AWS_QUEUE_URL,
            MessageBody=message_body
        )
        print(f"Message ID: {response['MessageId']}")
    table = dynamodb.Table('folders')
    response = table.update_item(
        Key={
            'partition_key': current_user,
            'sort_key': folder_name
        },
        UpdateExpression='SET isarchived = :true',
        ExpressionAttributeValues={
            ':true': True
        },
        ReturnValues='UPDATED_NEW'
    )
    return jsonify(logged_in_as=current_user), 200

@data_bp.route('/protected', methods=['GET'])
@jwt_required()
def protected():
    current_user = get_jwt_identity()  # Get the user ID from the JWT
    return jsonify(logged_in_as=current_user), 200




def get_dynamodb_folders(user_id):
    table_name = 'folders'
    table = dynamodb.Table(table_name)
    try:
        response = table.query(
            KeyConditionExpression="user_id = :uid",
            ExpressionAttributeValues={":uid": user_id}
        )
        return {item['folder']: item.get('isarchived', False) for item in response.get('Items', [])}
    except ClientError as e:
        print(f"Error fetching data from DynamoDB: {e.response['Error']['Message']}")
        return {}

def get_user_folders():
    """Retrieve folders from SQLAlchemy and merge `is_archived` from DynamoDB."""
    current_user = get_jwt_identity()
    
    # Fetch folders from SQLAlchemy
    folders = Folder.query.filter_by(user_id=current_user).all()

    # Fetch `is_archived` data from DynamoDB
    dynamo_data = get_dynamodb_folders(current_user)

    # Merge data
    folder_list = [{
        'id': folder.id,
        'name': folder.name,
        'asset_count': folder.asset_count,
        'size': folder.size,
        'is_deleted': folder.is_deleted,
        'is_archived': dynamo_data.get(folder.name),  # Merge field
        'created_at': folder.created_at,
        'updated_at': folder.updated_at
    } for folder in folders]

    return jsonify(folder_list), 200

@data_bp.route('/folders', methods=['GET'])
@jwt_required()
def get_folders():
    current_user = get_jwt_identity()
    folders = Folder.query.filter_by(user_id=current_user).all()
    folder_list = [{
        'id': folder.id,
        'name': folder.name,
        'asset_count': folder.asset_count,
        'size': folder.size,
        'is_deleted': folder.is_deleted,
        'is_archived': folder.is_archived,
        'created_at': folder.created_at,
        'updated_at': folder.updated_at
    } for folder in folders]
    return jsonify(folder_list), 200


folders_table = dynamodb.Table("folders")

@data_bp.route('/cfolder', methods=['POST'])
@jwt_required()
def create_folder():
    folder_name = request.json.get('name')
    if not folder_name:
        return jsonify({"msg": "Folder name is required"}), 400
    
    current_user = get_jwt_identity()
    print(current_user)
    user = User.query.get(current_user)  # Fetch user from DB
    mail = user.email

    new_folder = Folder(
        name=folder_name,
        user_id=current_user,
        is_deleted=False,
        is_archived=False,
        asset_count=0,
        restored_asset_count=0
    )
    db.session.add(new_folder)
    db.session.commit()
    try:
        folders_table.put_item(
            Item={
                'user': f"{current_user}",
                'folder': new_folder.name,
                'asset_count': str(new_folder.user_id),
                'archived_assets': 0,
                'mail': mail,
                'isarchived': False
            }
        )
    except Exception as e:
        print(e)
        return jsonify({"msg": "Error saving to DynamoDB", "error": str(e)}), 500
    
    return jsonify({
        'id': new_folder.id,
        'name': new_folder.name,
        'asset_count': new_folder.asset_count,
        'size': new_folder.size,
        'is_deleted': new_folder.is_deleted,
        'is_archived': new_folder.is_archived
    }), 201

@data_bp.route('/<int:folder_id>/archive', methods=['PUT'])
def archive_folder(folder_id):
    folder = Folder.query.get_or_404(folder_id)
    folder.is_archived = True
    db.session.commit()
    return jsonify({
        'msg': 'Folder archived successfully',
        'folder': {'id': folder.id, 'name': folder.name, 'is_archived': folder.is_archived}
    }), 200

@data_bp.route('/<int:folder_id>/delete', methods=['PUT'])
def delete_folder(folder_id):
    folder = Folder.query.get_or_404(folder_id)
    folder.is_deleted = True
    db.session.commit()
    return jsonify({
        'msg': 'Folder deleted successfully',
        'folder': {'id': folder.id, 'name': folder.name, 'is_deleted': folder.is_deleted}
    }), 200


'''
i have a dynamodb table now i want read each record based on the inserted time. fisrt come first server.
do the following
read the row (last_inserted and restore initiated field is False )
the record has a path key
read the path 
from a bucket called sharathmayarchive, restore the object at the given path.
now update the same row as restore _initiated as true
------------------------------------

read record whre restore initiated is true 
extract path of the object
read the head of the object with the path(s3 key) from the bucket.
if the object is restored delete the record from dynamodb table
check if restored by fetching the Restore='' field in the head object of the s3 object.
else do nothing
if the restore is in progress do nothing
if the restore is finished delete the record of the dynamodb
then,
-----
1. copy the restore object from the bucket to a destination bucket as a standard class



2. update the postgres count
3. if the restoore count == 0 send an sns notification. 

if the restore field is not present, and still  restore initiated is true then update the restore initiated to false .



connect to the postgres table called folders and decrese the count called pending_restored by one
if the pending restored becomes zero after the updation , push an event into an sqs queue saying "a folder is restored"


-----------------------------




'''


