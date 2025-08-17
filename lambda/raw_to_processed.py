import boto3

s3 = boto3.client('s3')

PROCESSED_BUCKET = 'marketing-processed-bucket-2025-jonatha'

def lambda_handler(event, context):
    for record in event['Records']:
        raw_bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        # Baixa o arquivo JSON
        obj = s3.get_object(Bucket=raw_bucket, Key=key)
        content = obj['Body'].read()
        
        # Define a chave de destino
        processed_key = f"processed/{key.split('/')[-1]}"

        # Job pyspark (?)
        # Tratamento de dados nulos
        # Normalização
        # Novas colunas
        
        # Grava no bucket processed
        s3.put_object(Bucket=PROCESSED_BUCKET, Key=processed_key, Body=content)
        
    return {'status': 'success'}
