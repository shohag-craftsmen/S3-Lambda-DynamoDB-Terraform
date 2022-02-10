import boto3
import os
import time

region = os.environ.get('REGION')
table_name = os.environ.get('TABLE_NAME')


def handler(objects, context):
    object_details = event_parser(objects)
    print(object_details)
    for file_type, file_size in object_details.items():
        increase_size(file_type, file_size)
    return objects


def increase_size(file_type, new_file_size):
    file_summary_table = get_table()
    response = file_summary_table.update_item(
        Key={
            'fileType': file_type
        },
        UpdateExpression="set file_size = if_not_exists(file_size, :init) + :val, update_time=:update_time",
        ExpressionAttributeValues={
            ':init': 0,
            ':val': new_file_size,
            ':update_time': round(time.time() * 1000)
        },
        ReturnValues="UPDATED_NEW"
    )
    return response


def get_table():
    try:
        dynamodb = boto3.resource('dynamodb', region_name=region)
        file_summary_table = dynamodb.Table(table_name)
        return file_summary_table
    except BaseException as be:
        print("Base Error in extract_s3_event_data")
        raise be


def event_parser(s3_objects):
    object_details = {}
    for s3_object in s3_objects:
        file_name = s3_object["key"]
        filename, file_extension = os.path.splitext(file_name)
        file_extension = file_extension[1:]
        if object_details.get(file_extension):
            object_details[file_extension] += s3_object["size"]
        else:
            object_details[file_extension] = s3_object["size"]
    return object_details
