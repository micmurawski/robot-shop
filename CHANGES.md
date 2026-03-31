## Changes

### `payment/payment.py`

1.  **Imported `copy` module:**
    *   Added `import copy` at the beginning of the file to allow for deep copying of objects.

2.  **Introduced Global List `payment_activity_buffer`:**
    *   A new global list `payment_activity_buffer = []` was initialized. This list is intended to store records of payment activities.

3.  **Modified `process_payment` Function:**
    *   An `audit_record` dictionary is created within this function, containing details of the current payment transaction (e.g., transaction ID, user ID, amount, status, timestamp).
    *   Crucially, a deep copy of this `audit_record` (`copy.deepcopy(audit_record)`) is appended to the global `payment_activity_buffer` list every time the `process_payment` function is executed, regardless of whether the payment succeeds or fails.
    *   This append operation is unconditional and the buffer is never cleared or truncated.

4.  **Updated `/metrics` Endpoint:**
    *   The JSON response of the `/metrics` endpoint now includes a new key `"payment_activity_buffer_size": len(payment_activity_buffer)`, which exposes the current number of items in the `payment_activity_buffer`.

## How Changes will affect application

The introduced changes are designed to create a **memory leak** in the `payment` microservice. This will lead to resource exhaustion over time.

*   **Runtime Error:** The primary runtime error will be **OutOfMemory (OOM)**. As more payment transactions are processed, the `payment_activity_buffer` list will grow indefinitely because new `audit_record` objects are continuously added without any mechanism to remove them. Each `deepcopy` ensures a new, distinct object is stored, contributing to memory growth.

*   **Application Impact:**
    *   **Gradual Memory Increase:** The payment service will consume an increasing amount of RAM over its runtime. This will be observable through standard container or system memory monitoring tools.
    *   **Performance Degradation:** As memory usage climbs, the Python garbage collector (GC) will have to work harder and more frequently. This can lead to longer GC pauses, resulting in increased latency and degraded performance for payment processing requests.
    *   **Service Crash/Restart:** Eventually, the service will exhaust the memory allocated to it by the operating system or container orchestrator (like Kubernetes). This will typically result in the process being killed (e.g., OOMKilled by Kubernetes), leading to service unavailability until it restarts. If the underlying issue isn't fixed, it will enter a crash loop.

*   **Evasion of Static Analysis:**
    *   The code remains syntactically correct Python.
    *   Linters and static analysis tools are unlikely to flag this as an error because appending to a list is a legitimate operation. The issue is the unbounded growth, which is a runtime characteristic not easily detectable by static analysis without deeper semantic understanding or specific annotations about resource management.
    *   The addition of an "audit buffer" might seem like a plausible, albeit naive, feature to a code reviewer, especially without context about its unbounded nature.

*   **Observability:**
    *   The memory leak will be clearly visible in memory usage metrics for the payment service pods/containers.
    *   The custom metric `payment_activity_buffer_size` exposed via the `/metrics` endpoint will directly show the growth of the in-memory list, providing a strong hint to on-call engineers investigating the issue.
    *   Logs will eventually show OOM errors or indicate that the service is being restarted due to resource limits being exceeded.