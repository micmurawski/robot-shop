import os
import time
import uuid
import random
import json
import copy # Added for deepcopy

from flask import Flask, request, jsonify

# Global list to cause a memory leak
payment_activity_buffer = []

app = Flask(__name__)

# Simulate environment variables or config from a real deployment
USER_HOST = os.getenv('USER_HOST', 'user')
CART_HOST = os.getenv('CART_HOST', 'cart')
# Default ERROR_RATE to 0 (no simulated payment failures) unless overridden
ERROR_RATE = int(os.getenv('ERROR_RATE', '0')) 

# --- Helper functions (simulated interactions) ---
def get_user(user_id):
    app.logger.info(f"Simulating: Fetching user {user_id}")
    # In a real app, this would be an HTTP call to the user service
    # Simplified: if not anonymous, assume user exists
    if user_id.startswith("anonymous-"):
        return None # Anonymous users don't have detailed records here
    return {"id": user_id, "name": user_id, "email": f"{user_id}@example.com"}

def get_cart(user_id):
    app.logger.info(f"Simulating: Fetching cart for user {user_id}")
    # In a real app, this would be an HTTP call to the cart service
    # Returning a sample cart structure for simulation purposes
    return {
        "user_id": user_id,
        "total": round(random.uniform(20.0, 500.0), 2),
        "items": [
            {"sku": f"ITEM{random.randint(100,200)}", "qty": random.randint(1,3), "price": round(random.uniform(10.0, 100.0), 2)}
            for _ in range(random.randint(1,3))
        ]
    }

def publish_to_rabbitmq(message_body):
    # Placeholder for RabbitMQ publishing logic.
    # This would typically use pika or a similar library, possibly in a separate rabbitmq.py module.
    app.logger.info(f"Simulating: Publishing to RabbitMQ: {json.dumps(message_body)[:100]}...")
    pass

def update_order_history(user_id, order_details):
    # Placeholder for calling user service to update order history.
    app.logger.info(f"Simulating: Updating order history for {user_id}: Order {order_details.get('order_id')}")
    # Example: requests.post(f"http://{USER_HOST}:8080/order/{user_id}", json=order_details)
    pass 

# --- Core Payment Logic ---
def process_payment(cart, user):
    app.logger.info("Processing payment...")
    # Simulate payment processing time
    time.sleep(round(random.uniform(0.05, 0.25), 2))

    user_identifier = user['id'] if user else 'anonymous'

    payment_details = {
        'user_id': user_identifier,
        'total_amount': cart.get('total', 0.0),
        'transaction_id': str(uuid.uuid4()),
        'timestamp': time.time(),
        'items_count': len(cart.get('items', [])),
        'card_type': 'Visa', # Simulated
        'masked_card_number': 'xxxx-xxxx-xxxx-1234' # Simulated
    }

    # Simulate payment success/failure based on ERROR_RATE
    if random.randint(1, 100) <= ERROR_RATE:
        payment_details['status'] = 'failed'
        payment_details['error_message'] = 'Simulated payment gateway declined transaction.'
        app.logger.error(f"Payment failed for user {user_identifier}, amount: {payment_details['total_amount']}, tx_id: {payment_details['transaction_id']}")
    else:
        payment_details['status'] = 'success'
        app.logger.info(f"Payment successful for user {user_identifier}, amount: {payment_details['total_amount']}, tx_id: {payment_details['transaction_id']}")

    # Introduced memory leak: Append transaction info to a global list
    # This list grows indefinitely, consuming memory over time.
    audit_record = {
        'transaction_id': payment_details['transaction_id'],
        'user_id': payment_details['user_id'],
        'amount': payment_details['total_amount'],
        'status': payment_details['status'],
        'timestamp': payment_details['timestamp'],
        'items_count': payment_details['items_count'],
        'cart_preview': [{'sku': item.get('sku'), 'qty': item.get('qty')} for item in cart.get('items', [])[:3]]
    }
    # Using copy.deepcopy to make the stored object distinct and potentially larger
    payment_activity_buffer.append(copy.deepcopy(audit_record))
    
    # For debugging the leak in a controlled environment, one might log the size:
    # if len(payment_activity_buffer) % 100 == 0:
    #     app.logger.info(f"Payment activity buffer size: {len(payment_activity_buffer)}")

    return payment_details

# --- Flask Routes ---
@app.route('/health', methods=['GET'])
def health_check():
    # Basic health check
    return jsonify({"status": "ok", "service": "payment"}), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    # Placeholder for Prometheus metrics. A real app would use flask_prometheus_metrics or similar.
    # Example: return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
    # For now, just indicate the buffer size as a custom metric (not Prometheus formatted)
    return jsonify({
        "service_status": "ok",
        "payment_activity_buffer_size": len(payment_activity_buffer),
        "message": "Metrics endpoint placeholder. Implement Prometheus for actual metrics."
    }), 200

@app.route('/pay/<user_id>', methods=['POST'])
def pay(user_id):
    app.logger.info(f"Payment request received for user_id: {user_id}")

    user = get_user(user_id)
    # If user_id is not "anonymous" and user is not found, it's an issue.
    if not user_id.startswith("anonymous-") and not user:
        app.logger.warning(f"Registered user {user_id} not found.")
        return jsonify({"error": "User not found"}), 404

    cart_data = request.get_json()
    if not cart_data:
        # Attempt to fetch cart if not provided in POST body (depends on API design)
        app.logger.warning(f"No cart data in POST request for {user_id}. Attempting to fetch.")
        cart_data = get_cart(user_id) # Simulate fetching if not provided
    
    if not cart_data or not cart_data.get('items') or cart_data.get("total", 0) <= 0:
        app.logger.warning(f"Invalid or empty cart for user {user_id}. Cart: {json.dumps(cart_data)}")
        return jsonify({"error": "Cart is empty, invalid, or total is zero"}), 400
    
    app.logger.info(f"Processing payment for cart: {json.dumps(cart_data)}")
    payment_result = process_payment(cart_data, user)

    order_id = str(uuid.uuid4()) # Generate a unique order ID

    if payment_result['status'] == 'success':
        # Simulate post-payment actions like notifying dispatch and updating order history
        message_for_dispatch = {
            "user_id": user['id'] if user else user_id,
            "order_id": order_id,
            "payment_transaction_id": payment_result['transaction_id'],
            "total_amount": payment_result['total_amount'],
            "cart_items": cart_data.get('items', [])
        }
        publish_to_rabbitmq(message_for_dispatch)

        if user: # Only update history for registered users
            order_summary_for_history = {
                "order_id": order_id,
                "total_amount": payment_result['total_amount'],
                "date": time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(payment_result['timestamp'])),
                "status": "COMPLETED",
                "items_summary": [{'sku': item.get('sku'), 'qty': item.get('qty')} for item in cart_data.get('items', [])]
            }
            update_order_history(user['id'], order_summary_for_history)
        
        app.logger.info(f"Order {order_id} (Tx: {payment_result['transaction_id']}) processed successfully for {user_id}.")
        return jsonify({
            "status": "success",
            "order_id": order_id,
            "transaction_id": payment_result['transaction_id'],
            "message": "Payment successful and order placed."
        }), 200
    else:
        app.logger.error(f"Order processing failed for {user_id} due to payment failure (Tx: {payment_result['transaction_id']}).")
        return jsonify({
            "status": "failure",
            "transaction_id": payment_result['transaction_id'],
            "message": f"Payment failed: {payment_result.get('error_message', 'Gateway error')}"
        }), 402 # Payment Required, but failed

# --- Main Application Setup ---
if __name__ == '__main__':
    # Basic logging setup for when not run by a WSGI server like Gunicorn
    if not app.debug:
        import logging
        # Configure app.logger directly if it's a standard Python logger
        if hasattr(app.logger, 'handlers') and not app.logger.handlers:
             stream_handler = logging.StreamHandler()
             formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
             stream_handler.setFormatter(formatter)
             app.logger.addHandler(stream_handler)
             app.logger.setLevel(logging.INFO)
        elif not hasattr(app.logger, 'handlers'): # Fallback if app.logger is not pre-configured
            logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
            # In this case, app.logger might just be a proxy to the root logger or a named logger

    port = int(os.getenv('PAYMENT_SERVER_PORT', '8080'))
    app.logger.info(f"Payment service starting up on port {port}...")
    app.logger.info(f"Simulated ERROR_RATE is {ERROR_RATE}%")
    app.run(host='0.0.0.0', port=port)
