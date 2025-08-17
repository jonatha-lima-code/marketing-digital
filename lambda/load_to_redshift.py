import os
import json
import boto3

s3 = boto3.client('s3')

BUCKET_RAW = os.environ['S3_BUCKET_RAW']
PREFIX_RAW = os.environ.get('S3_PREFIX_RAW', 'raw-data/')

def lambda_handler(event, context):
    for record in event.get('Records', []):
        # Supondo que o payload esteja em record['body'] (para eventos Kinesis ou outro trigger)
        data = json.dumps(record)  # ou record['body'] se for Kinesis
        key = f"{PREFIX_RAW}{record['eventID']}.json"
        s3.put_object(Bucket=BUCKET_RAW, Key=key, Body=data.encode('utf-8'))

    return {"status": "ok", "records": len(event.get('Records', []))}

