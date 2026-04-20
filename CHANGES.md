## Changes

- Modified `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`:
    - Introduced a static `AtomicLong` counter (`calculationCount`) to track the number of calls to the `/calc/{id}` endpoint.
    - Added a `Thread.sleep` call within the `/calc/{id}` method. The sleep duration is calculated based on the current value of `calculationCount`, causing the delay to increase over time with each call.

## How Changes will affect application

The introduced change in the `shipping` service's `/calc/{id}` endpoint will cause a performance degradation that worsens over time. As more requests are made to this endpoint, the static counter `calculationCount` will increment, leading to a longer `Thread.sleep` duration for each subsequent request.

This increasing delay will manifest as:

-   **Increased Latency:** The response time for the `/calc/{id}` endpoint will become progressively slower.
-   **Timeouts:** Eventually, the delay will exceed the timeout configurations of the services calling the shipping service (e.g., the `web` service), leading to failed requests.
-   **Resource Exhaustion:** While not a direct memory leak, the threads handling the `/calc/{id}` requests in the shipping service will be blocked during the `Thread.sleep`. If the request rate is high, this can lead to thread pool exhaustion in the shipping service, preventing it from processing new requests and potentially impacting other endpoints.
-   **Error Logs:** Calling services will likely log errors related to timeouts or failed connections to the shipping service.
-   **Observability:** The increasing latency and potential error rates will be clearly visible in monitoring tools (e.g., dashboards showing service metrics). Tracing tools will show spans for the `/calc/{id}` endpoint taking significantly longer, and the `Thread.sleep` duration might be visible within the span details, indicating the cause of the delay.