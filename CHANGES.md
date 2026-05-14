## Incident Response Training Exercise: Memory Leak in Catalogue Service

This document outlines the changes made to the `catalogue` microservice to simulate a memory leak for an incident response training exercise.

### Changes

The following modifications were made to the `catalogue/server.js` file:

1.  **Global Array Initialization:**
    *   A new global array named `detailedProductViewStats` was declared and initialized as an empty array:
        ```javascript
        const detailedProductViewStats = [];
        ```

2.  **Data Collection in Product Detail Endpoint:**
    *   Within the `app.get('/product/:sku', ...)` route handler, specifically when a product is successfully retrieved, code was added to collect and store request details.
    *   For every successful call to this endpoint, an object containing the `sku`, `timestamp`, requestor's `ip`, and `userAgent` is pushed into the `detailedProductViewStats` array.
        ```javascript
        detailedProductViewStats.push({
            sku: req.params.sku,
            timestamp: new Date().toISOString(),
            ip: req.ip,
            userAgent: req.headers['user-agent']
        });
        ```
    *   A conditional log statement was added to output the size of the `detailedProductViewStats` array every 100 entries, aiding in observing the leak's progression:
        ```javascript
        if (detailedProductViewStats.length % 100 === 0) {
            req.log.info(`detailedProductViewStats has ${detailedProductViewStats.length} entries.`);
        }
        ```

### How Changes Affect Application

These changes introduce a deliberate memory leak into the `catalogue` microservice.

*   **Memory Exhaustion:** The `detailedProductViewStats` array is never cleared or truncated. As the `/product/:sku` endpoint is called (which happens frequently under load, especially by the `load-gen/robot-shop.py` script), this array will grow indefinitely, consuming more and more memory.
*   **Service Degradation and Crash:** Over time, the increasing memory footprint will lead to performance degradation of the `catalogue` service. Eventually, the Node.js process will exhaust available memory, leading to an Out Of Memory (OOM) error, causing the service to crash.
*   **Observability:**
    *   **Metrics:** Monitoring tools will show a steady increase in memory usage for the `catalogue` service container/process.
    *   **Logs:** Application logs will contain messages like `detailedProductViewStats has X entries`, clearly indicating the growing array. Eventually, OOM error messages will appear in the logs when the service crashes.
*   **Impact on System:** When the `catalogue` service crashes, any services depending on it (e.g., the `web` service for displaying product information) will be impacted, likely resulting in errors or inability to serve product-related requests to users.
*   **Trigger Condition:** The `load-gen/robot-shop.py` testing script will reliably trigger this memory leak by simulating users browsing product details, thus repeatedly hitting the `/product/:sku` endpoint.