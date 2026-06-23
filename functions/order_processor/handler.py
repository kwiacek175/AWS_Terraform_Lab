import json
import boto3
import os

s3 = boto3.client("s3")
sns = boto3.client("sns")

BUCKET = os.environ["ORDER_BUCKET"]
TOPIC = os.environ["NOTIFY_TOPIC_ARN"]


def process_order(order):
    total = order["quantity"] * order["unit_price"]
    priority = "high" if total > 1000 else "normal"

    result = {
        **order,
        "total": total,
        "priority": priority,
        "processed": True
    }

    s3.put_object(
        Bucket=BUCKET,
        Key=f"processed/{order['order_id']}.json",
        Body=json.dumps(result),
        ContentType="application/json"
    )

    sns.publish(
        TopicArn=TOPIC,
        Subject=f"Order {order['order_id']} processed",
        Message=json.dumps(result, indent=2)
    )

    return result


def lambda_handler(event, context):

    # Step Functions
    if "Records" not in event:
        order = event.get("order", event)
        return process_order(order)

    # SQS
    for record in event["Records"]:
        order = json.loads(record["body"])
        process_order(order)

    return {"status": "ok"}