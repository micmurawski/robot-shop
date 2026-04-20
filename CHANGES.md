## Changes

*   **Modified File**: `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`
    *   In the `free()` method, the line `bytesGlobal.clear();` which is responsible for clearing a statically held list of byte arrays, has been commented out.

## How Changes will affect application

The introduced change is designed to create a memory leak in the `shipping` service under specific conditions:

1.  **Memory Allocation**: The `/memory` endpoint in the `Controller.java` allocates a 25MB byte array (`byte[] bytes = new byte[1024 * 1024 * 25];`) and adds it to a static `List<byte[]> bytesGlobal`.
2.  **Memory Release Disabled**: The `/free` endpoint was originally intended to clear this `bytesGlobal` list, thereby releasing the allocated memory. By commenting out `bytesGlobal.clear();`, this memory reclamation mechanism is disabled.
3.  **Cumulative Effect**: Each call to the `/memory` endpoint will now add 25MB to the `bytesGlobal` list without any subsequent calls to `/free` being able to release this accumulated memory.
4.  **Resource Exhaustion**: Over time, if the `/memory` endpoint is called repeatedly, the `bytesGlobal` list will grow indefinitely. This will lead to a continuous increase in the heap memory usage of the shipping service's JVM.
5.  **Runtime Error**: Eventually, the JVM will exhaust its available heap space, leading to an `java.lang.OutOfMemoryError`. This will likely cause the shipping service to become unresponsive, unstable, or crash entirely.
6.  **Impact on Observability**: Monitoring tools should show a steadily increasing memory utilization for the shipping service. When the `OutOfMemoryError` occurs, error logs will be generated, and the service might enter a crash loop or become unavailable, which should trigger alerts if configured.
7.  **Stealth**: The change is subtle (a commented-out line) and does not introduce any compilation errors or static analysis warnings. It might be overlooked during a code review as a temporary debugging measure or an oversight.