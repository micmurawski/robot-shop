## Changes

- Modified `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`.
- In the `caclc(@PathVariable long id)` method, added a conditional block:
  - If the input `id` is even (`id % 2 == 0`),
  - A new byte array of 10MB is allocated (`new byte[1024 * 1024 * 10]`).
  - This byte array is added to the static `bytesGlobal` list (`bytesGlobal.add(bytes)`).

## How Changes will affect application

The introduced change creates a conditional memory leak in the Shipping service. The `/calc/{id}` endpoint is used to calculate shipping costs based on a city ID. The modification causes the service to allocate a significant amount of memory (10MB) and hold onto it indefinitely in a static list *only* when the provided city `id` is an even number.

This change will pass compilation and static analysis because allocating byte arrays and adding them to a list are valid Java operations. The error is purely a runtime issue related to resource management.

During application execution, if the Shipping service receives multiple requests to the `/calc/{id}` endpoint with even `id` values, the `bytesGlobal` list will continuously grow. Each such request adds another 10MB to the service's memory footprint. Over time, as more even IDs are processed, the Shipping service will consume increasing amounts of heap memory. Eventually, it will exhaust the available memory, leading to an `OutOfMemoryError` and causing the service to crash or become unresponsive.

This issue is difficult for on-call engineers to diagnose because:
- The memory leak is conditional, only occurring for specific input data (even IDs), making it dependent on the traffic pattern.
- It's a gradual resource exhaustion problem that manifests over time, rather than an immediate crash on a specific code path.
- Standard logs might show increasing memory usage, but they won't directly point to the conditional allocation in the `/calc/{id}` method without detailed profiling or heap dumps, which are often complex to perform in a production incident scenario.
- The presence of the `/memory` and `/free` endpoints and the `bytesGlobal` list in the original code makes the addition of conditional memory allocation appear less suspicious in a code review, potentially masking the malicious intent.