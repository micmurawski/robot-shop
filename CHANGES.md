## Changes

### File: `dispatch/main.go`

- **Imported `sync/atomic`:** This package was added to provide atomic counter operations, ensuring thread-safe incrementing of the `dispatchCounter`.
- **Added Global Variable `dispatchCounter`:** A new global variable `dispatchCounter int32 = 0` was introduced. This counter tracks the number of messages processed by the `createSpan` function.
- **Introduced Controlled Failure Logic in `createSpan` function:**
    - At the beginning of the function, `dispatchCounter` is atomically incremented.
    - A conditional check was added: `if currentCount == 5`.
    - If the counter reaches 5, a log message "INFO: Controlled failure scenario triggered. Inducing panic on 5th dispatch message." is printed.
    - A nil pointer dereference is then intentionally triggered by declaring a nil string pointer (`var deliberatelyNil *string`) and attempting to assign a value to it (`*deliberatelyNil = "trigger_panic"`). This action will cause a runtime panic.

## How Changes Affect Application

The introduced changes are designed to create a controlled failure scenario specifically within the `dispatch` microservice for incident response training purposes.

1.  **Dispatch Service Crash:** The `dispatch` service will now crash reliably after processing its 5th message from the RabbitMQ "orders" queue. The crash is due to a deliberate nil pointer dereference, which results in a Go runtime panic.
2.  **Trigger Condition:** The failure is not immediate upon startup but is triggered by the processing of messages. The `load-gen/robot-shop.py` script, by sending orders, will eventually cause the `dispatch` service to process enough messages to hit the 5th message threshold and trigger the panic.
3.  **Observable Symptoms:**
    *   **Error Logs:** The `dispatch` service logs will show the panic message and a stack trace, clearly indicating the nil pointer dereference as the cause of the crash.
    *   **Service Unavailability:** The `dispatch` service will become unavailable after the crash. If running under an orchestrator like Kubernetes, it will likely be restarted, only to crash again after processing another 5 messages (unless the underlying issue is "fixed" as part of the training exercise).
    *   **Message Queue Behavior:** Messages destined for the `dispatch` service (orders) will start to accumulate in the RabbitMQ "orders" queue, as there will be no healthy consumer if the service is down or in a crash loop. This can be observed via RabbitMQ management tools or metrics.
    *   **Downstream Impact (Potential):** Since `dispatch` coordinates between `shipping` and `payment` (as per `DOC.md`), its failure will prevent order fulfillment. Users might not receive order confirmations, or the order process might stall at the point where `dispatch` is involved.
    *   **Metrics Anomalies:** Monitoring dashboards should show anomalies related to the `dispatch` service: error rates spiking, processing rates dropping to zero, and potentially health check failures.

This controlled failure allows the on-call team to practice detecting the issue using observability tools, diagnosing the root cause by analyzing logs and metrics, and implementing remediation strategies in a safe training environment.