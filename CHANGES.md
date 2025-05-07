## Changes

- **File:** `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`
- **Modification:** In the `memory()` method, the size of the byte array allocated was increased from `1024 * 1024 * 25` (25 MB) to `1024 * 1024 * 250` (250 MB).

## How Changes will affect application

The modification introduces a controlled memory leak in the Shipping service. The `/memory` endpoint, when called, allocates a 250 MB byte array and adds it to a static list (`bytesGlobal`). This list is only cleared by explicitly calling the `/free` endpoint.

Repeatedly accessing the `/memory` endpoint will cause the Shipping service's heap memory to be consumed rapidly. Each call adds another 250 MB to the process's memory footprint. Since the list is static and holds references to these large byte arrays, the garbage collector cannot free the memory.

This will inevitably lead to an `OutOfMemoryError` (OOM) in the Shipping service process. Depending on the JVM configuration and available memory, this error will occur after a relatively small number of calls to the `/memory` endpoint (approximately 8-10 calls if the heap size is around 2GB, for example). The service instance will likely crash or become unresponsive.

In an orchestrated environment like Kubernetes, the crashing pod will be detected, and a new instance will likely be started. However, if the `/memory` endpoint is hit frequently (e.g., by a misconfigured health check or an attacker), the service will enter a crash loop, making it unavailable.

This issue will be visible in observability tools through:

- **Increased Memory Usage:** Graphs showing the heap usage of the Shipping service will show a steep increase with each call to `/memory`.
- **Error Logs:** `OutOfMemoryError` exceptions will appear in the service logs.
- **Service Restarts/Unavailability:** Monitoring will show the Shipping service instances crashing and restarting, or becoming unhealthy and being replaced.
- **Impact on Dependent Services:** The Web service and Dispatch service, which depend on the Shipping service, may experience errors or timeouts when trying to communicate with it, particularly during the checkout process.

The change is designed to evade static analysis as it involves a standard memory allocation operation within a seemingly valid method, and the memory leak is a runtime consequence of repeated execution and state accumulation (the growing `bytesGlobal` list), which static analysis tools typically cannot predict or detect reliably.