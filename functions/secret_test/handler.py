import boto3
import os

ssm = boto3.client("ssm")

def lambda_handler(event, context):
    response = ssm.get_parameter(
        Name=os.environ["DB_PASSWORD"],
        WithDecryption=True
    )

    password = response["Parameter"]["Value"]

    print("DB PASSWORD:", password)

    return {
        "statusCode": 200,
        "body": password
    }