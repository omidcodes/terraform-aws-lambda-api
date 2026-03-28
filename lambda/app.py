import json


def handler(event, context):
    """
    This follows the Lambda Python handler model, and the returned object matches the API Gateway Lambda proxy response format. If Lambda returns a different format, API Gateway can return an error such as 502 Bad Gateway.
    """
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "method": event.get("requestContext", {}).get("http", {}).get("method"),
            "path": event.get("rawPath")
        })
    }