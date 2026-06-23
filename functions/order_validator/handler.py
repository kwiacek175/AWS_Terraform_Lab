def lambda_handler(event, context):
    order = event.get("order", event)

    errors = []

    if order.get("quantity", 0) < 1:
        errors.append("quantity invalid")

    if order.get("unit_price", 0) <= 0:
        errors.append("unit_price invalid")

    return {
        "order": order,
        "valid": len(errors) == 0,
        "errors": errors
    }