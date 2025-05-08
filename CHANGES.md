## Changes

### cart/server.js

- **Introduced a Memory Leak:**
    - A new global array `activeProductRequests` was added.
    - In the `getProduct(sku)` function, a `requestRecord` object (containing `sku` and `initiatedTime`) is now created and pushed into the `activeProductRequests` array upon every invocation.
    - Crucially, these `requestRecord` objects are never removed from the `activeProductRequests` array, leading to unbounded growth of this array over time as more products are fetched (typically when items are added to the cart).
- **Error Handling Improvement (Incidental to the leak):**
    - Added a `try-catch` block around `JSON.parse(body)` within the `getProduct` function to handle potential errors during parsing of the product data received from the catalogue service. This change, while good practice, is not the source of the intentional error but helps make the introduced leaking code less obvious.

## How Changes Affect Application

- **Memory Exhaustion in Cart Service:** The primary impact is a memory leak within the `cart` microservice. Each time a product's details are fetched (e.g., when a user adds an item to their cart via the `/api/cart/add/:id/:sku/:qty` endpoint), an object is added to the `activeProductRequests` array. Since this array is never cleared or pruned, the memory consumed by the `cart` service will continuously increase as the application is used.
- **Performance Degradation:** As memory usage grows, the Node.js garbage collector will work harder and more frequently, potentially leading to increased CPU usage and longer pauses. This can result in slower response times for cart operations and other requests handled by the `cart` service.
- **Service Unavailability:** Eventually, the `cart` service will exhaust its allocated memory. This will likely cause the Node.js process to crash due to an Out Of Memory (OOM) error. If running in an orchestrated environment like Kubernetes, the pod will be restarted, but the issue will recur as long as the service is under load.
- **Impact on Dependent Services:** While other services don't directly consume memory from the cart service, its unavailability will affect any service that relies on it. For example, the `web` service will fail to add items to the cart or display cart contents if the `cart` service is down or unresponsive.
- **Observability Signals:**
    - **Metrics:** A steady increase in memory utilization for the `cart` service container/pod will be the most direct indicator. CPU usage might also show an upward trend over time. Latency for cart-related endpoints may increase before a crash.
    - **Logs:** Error logs indicating OOM errors or service crashes will appear once the memory limit is reached. Prior to that, there might not be specific error logs related to the leak itself, only standard operational logs.
- **Trigger Condition:** The `load-gen/robot-shop.py` script, by simulating users adding items to carts, will reliably trigger the `getProduct` function calls, thus accelerating the memory leak and making its effects observable during the training exercise.