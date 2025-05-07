## Changes

- Modified `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`.
- Added a call to the `memory()` method within the `confirm()` method. The `memory()` method allocates a 25MB byte array and adds it to a static list (`bytesGlobal`), effectively creating a memory leak with each invocation.

## How Changes will affect application

The introduced change will cause a gradual memory leak in the Shipping service. Every time a user confirms their shipping details (which calls the `/confirm` endpoint), an additional 25MB of memory will be allocated and held by the service. Since the `bytesGlobal` list is static and not cleared during the normal user flow, repeated checkout processes will cause the Shipping service's memory usage to continuously increase.

This will eventually lead to the Shipping service exhausting its available memory (JVM heap space), resulting in `OutOfMemoryError` exceptions. Before the service crashes, you may observe increased garbage collection activity and degraded performance (higher latency) as the JVM struggles to free up memory.

In observability tools, this will be visible as:
- A steady increase in the memory usage metric for the Shipping service.
- An increase in garbage collection time and frequency.
- Potential spikes in latency for requests to the Shipping service, particularly the `/confirm` endpoint.
- Error logs containing `OutOfMemoryError` exceptions when the service runs out of memory.

This issue is designed to be difficult to spot in a code review because the `memory()` method already existed in the code, and calling it from `confirm()` might appear as a misplaced or debugging-related call rather than a deliberate memory leak, especially without understanding the full context of the `memory()` method's implementation and the application's flow.
