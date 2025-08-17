
#!/usr/bin/env python3
"""Publisher to send simulated events to Kinesis"""
import json, random, datetime, time, os
import boto3

region = os.getenv('AWS_REGION', 'sa-east-1')
stream_name = os.getenv('KINESIS_STREAM', 'marketing_events')

kinesis = boto3.client('kinesis', region_name=region)

today = datetime.date.today().isoformat()
campaigns = [
    ("google_ads", "G-123"),
    ("facebook_ads", "F-456"),
    ("google_ads", "G-789"),
    ("facebook_ads", "F-012"),
]

def gen_row(source, campaign_id):
    spend = round(random.uniform(50, 300), 2)
    clicks = random.randint(100, 3000)
    impressions = clicks * random.randint(5, 20)
    conversions = max(1, int(clicks * random.uniform(0.5, 3.0) / 100))
    revenue = round(conversions * random.uniform(20, 80), 2)
    return {
        "source": source,
        "date": today,
        "campaign_id": campaign_id,
        "spend": spend,
        "clicks": clicks,
        "impressions": impressions,
        "conversions": conversions,
        "revenue": revenue
    }

def main():
    for _ in range(200):
        s, c = random.choice(campaigns)
        msg = json.dumps(gen_row(s, c))
        kinesis.put_record(
            StreamName=stream_name,
            Data=msg.encode('utf-8'),
            PartitionKey=c
        )
        time.sleep(0.03)
    print('Published ~200 events to Kinesis stream', stream_name)

if __name__ == '__main__':
    main()
