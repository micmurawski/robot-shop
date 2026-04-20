## Changes

- **Modified `cart/server.js`:**
    - The `saveCart(id, cart)` function was updated to introduce a `change_log` field within the `cart` object.
    - On every invocation of `saveCart`, a new entry is appended to this `change_log`. This entry consists of a timestamp and a JSON string snapshot of the current `cart.items`.
    - If `cart.change_log` does not exist, it is initialized as an empty string before appending the first log entry.

```javascript
// Inside saveCart function:
if (!cart.change_log) { // Initialize if not present
    cart.change_log = "";
}
// Append current items state to the log.
let currentItemsSnapshot = JSON.stringify(cart.items);
cart.change_log += `[${new Date().toISOString()}] Snapshot: ${currentItemsSnapshot}\n`; // Append and add a newline
```

## How Changes Affect Application

The introduced modification is designed to cause a **Resource Exhaustion** issue at runtime, specifically targeting memory and potentially CPU resources.

1.  **Redis Memory Bloat:**
    *   Each time a cart is saved (which happens frequently with operations like adding items, updating quantities, or adding shipping information via `load-gen`), the `change_log` string within the cart object stored in Redis will grow.
    *   Over time and under load, this unbounded growth will lead to significantly larger cart objects being stored in Redis.
    *   This will consume an increasing amount of Redis memory, potentially leading to Redis hitting its `maxmemory` limit. When this happens, Redis might start evicting keys (which could include active carts or other critical data if not configured with a specific eviction policy) or reject further write commands, leading to errors in the cart service when trying to save carts.
    *   Observability tools should show a steady increase in Redis memory usage, and eventually, error logs from Redis (e.g., OOM errors) or from the cart service indicating failed writes to Redis.

2.  **Cart Service Performance Degradation & Memory Issues:**
    *   As cart objects become larger due to the bloated `change_log`, the `cart` microservice will consume more memory when fetching these objects from Redis and parsing them (using `JSON.parse()`).
    *   Serializing these large objects back to JSON strings (using `JSON.stringify()`) before saving them to Redis will also become more CPU-intensive.
    *   This can lead to slower API response times for all cart-related operations, increased CPU utilization, and higher memory consumption within the cart service itself.
    *   In extreme scenarios, the Node.js process running the cart service might encounter its own heap memory limits, leading to crashes or unresponsiveness.

3.  **Increased Network Traffic:**
    *   The transfer of larger cart objects between the cart service and Redis will result in increased network traffic, which could further contribute to latency under high load.

4.  **Impact on Load Generator and Testing:**
    *   The `load-gen/robot-shop.py` script performs actions that repeatedly call endpoints leading to `saveCart` (e.g., adding items, updating cart). This ensures that the `change_log` grows and the resource exhaustion issue is triggered during the load test.

This type of error evades static analysis because the code itself is syntactically valid, and the concept of adding a log or audit trail is a legitimate software pattern. The error only emerges at runtime due to the cumulative effect of repeated operations causing unbounded data growth.