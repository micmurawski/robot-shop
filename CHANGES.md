## Changes

- Modified `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`.
- In the `/calc/{id}` endpoint, added code to allocate a 5MB byte array (`new byte[1024 * 1024 * 5]`) and add it to the static `bytesGlobal` list.

## How Changes will affect application

The introduced change creates a subtle memory leak in the `shipping` service. Each time a user calculates shipping costs by calling the `/calc/{id}` endpoint, an additional 5MB of memory is allocated and stored in a static list (`bytesGlobal`). Because this list is static and the references to the byte arrays are maintained, the garbage collector cannot free this memory.

Over time, as users perform more shipping calculations, the memory usage of the `shipping` service will continuously increase. This gradual increase will initially manifest as rising memory consumption metrics for the service. Eventually, the service will exhaust its available heap space, leading to an `OutOfMemoryError` at runtime. This error will likely cause the `shipping` service instance to crash or become unresponsive.

Since the web service depends on the shipping service for the checkout process, the failure of the `shipping` service will prevent users from completing their orders. On-call engineers investigating the issue will observe the steadily increasing memory usage of the `shipping` service and the eventual `OutOfMemoryError` in the service logs and monitoring dashboards, providing clear indicators of the problem's nature and location. The change is designed to be difficult to spot in static analysis or a quick code review because it leverages an existing static list and the per-request allocation is not immediately catastrophic.