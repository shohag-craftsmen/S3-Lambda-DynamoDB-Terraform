import json
import boto3
import os
import uuid


def handler(event, context):
    # region = os.environ.get('REGION')
    state_machine_arn = os.environ.get('STEP_FN_ARN')
    # state_machine_name = os.environ.get('STEP_FN_NAME')

    client = boto3.client('stepfunctions')
    try:
        records = event_parser(event)
        response = client.start_execution(
            stateMachineArn=state_machine_arn,
            name=str(uuid.uuid4()),
            input=json.dumps(records)
        )
    except Exception as exception:
        raise exception


def event_parser(event):
    try:
        records = event['Records']
        s3_objects = []
        for record in records:
            s3_objects.append(record["s3"]["object"])
        return s3_objects
    except Exception as exception:
        raise ValueError('Invalid value')


