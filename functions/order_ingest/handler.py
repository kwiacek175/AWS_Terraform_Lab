import json, boto3, os

s3 = boto3.client("s3")
sqs = boto3.client("sqs")

BUCKET = os.environ["ORDER_BUCKET"]
QUEUE_URL = os.environ["ORDER_QUEUE_URL"]

def lambda_handler(event, context):
    body = event.get("body")
    order = json.loads(body) if isinstance(body, str) else event

    total = order["quantity"] * order["unit_price"]
    order["total"] = total

    key = f"orders/{order['order_id']}.json"

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(order)
    )

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(order)
    )

    return {
        "statusCode": 200,
        "body": json.dumps(order)
    }