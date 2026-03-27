## Changes

- **shipping/src/main/java/com/instana/robotshop/shipping/Controller.java:** Introduced a loop in the `caclc(@PathVariable long id)` method that creates and stores `String` objects in an `ArrayList`. The number of iterations is proportional to the `id` path variable.

## How Changes will affect application

The modification in the `shipping` service's `/calc/{id}` endpoint introduces a potential for **resource exhaustion**, specifically **memory consumption**. When this endpoint is called with a large `id` value, the service will allocate a significant amount of memory to the `temp_list`. Under sustained load, especially with varying or large `id` values, this will lead to:

- **Increased memory usage:** The service's memory footprint will grow, visible in memory usage metrics.
- **Performance degradation:** The Java garbage collector will work harder to manage the increasing memory, potentially causing application pauses and increased request latency.
- **OutOfMemoryError:** If the memory usage exceeds the allocated heap space, the service will crash, leading to unavailability of the shipping calculation functionality.

These issues will be observable through monitoring tools showing high memory utilization, increased garbage collection activity, and error logs indicating `OutOfMemoryError` when the service crashes.