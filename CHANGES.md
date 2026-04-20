## Changes

1.  **Global Array for Logging:**
    *   In `catalogue/server.js`, a new global array named `requestLogForPerformanceAnalysis` was initialized:
        ```javascript
        let requestLogForPerformanceAnalysis = [];
        ```

2.  **Request Data Logging in `/product/:sku` Route:**
    *   The route handler for `GET /product/:sku` in `catalogue/server.js` was modified to collect request data.
    *   On each request to this endpoint, an object containing the requested `sku`, the request `timestamp`, and the `userAgent` from the request headers is pushed into the `requestLogForPerformanceAnalysis` array:
        ```javascript
        // product by SKU
        app.get('/product/:sku', (req, res) => {
            if(mongoConnected) {
                if (req.params.sku) {
                    requestLogForPerformanceAnalysis.push({ sku: req.params.sku, requestedAt: new Date().toISOString(), userAgent: req.headers['user-agent'] });
                }
                // ... rest of the original code
            }
        });
        ```

## How Changes Affect Application

The introduced changes are designed to cause a **memory leak** in the `catalogue` service, leading to resource exhaustion over time.

*   **Error Type**: Resource Exhaustion (Memory Leak).
*   **Mechanism**: 
    *   The `requestLogForPerformanceAnalysis` array is a global variable within the `catalogue` service's Node.js process.
    *   With every incoming request to the `/product/:sku` endpoint (a frequent operation when users view product details), a new object containing request metadata is added to this array.
    *   Crucially, there is no mechanism implemented to clear, truncate, or process the data in this array. It will grow indefinitely as long as the service is running and receiving requests to view products.
*   **Runtime Manifestation**:
    *   As the `requestLogForPerformanceAnalysis` array continuously grows, the memory footprint of the `catalogue` service Node.js process will steadily increase.
    *   Eventually, the process will consume all available memory allocated to it by the operating system or container limits.
    *   This will result in an "Out of Memory" (OOM) error, causing the `catalogue` service to crash and become unavailable.
    *   Observability tools (metrics and logs) should show a pattern of increasing memory usage for the `catalogue` service, followed by a sudden termination or restart of the service, accompanied by error logs indicating memory exhaustion.
*   **Why it Evades Static Analysis**:
    *   The JavaScript code is syntactically correct and uses standard language features.
    *   Static analysis tools and linters are unlikely to flag this behavior as an error because adding elements to an array is a legitimate operation. They typically do not perform runtime-level analysis to detect unbounded growth of data structures unless specifically designed for such complex scenarios or if there are obvious anti-patterns (which are avoided here).
    *   The variable name `requestLogForPerformanceAnalysis` suggests a plausible, albeit poorly implemented, feature for logging or debugging, making the code appear legitimate at first glance.
*   **Why it's Difficult to Spot in Code Reviews**:
    *   The change is minimal—a new array declaration and a single line of code within an existing route handler.
    *   The purpose, as implied by the variable name, seems benign (e.g., temporary logging for performance analysis that a developer might forget to remove or properly implement).
    *   Reviewers might not immediately recognize the lack of a cleanup mechanism for this in-memory array, especially in a larger changeset or if not specifically looking for memory-related issues.