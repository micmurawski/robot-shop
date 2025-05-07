## Changes

-   In `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`, a call to the `memory()` method was added within the `caclc(@PathVariable long id)` method.

## How Changes will affect application

The introduced change will cause a gradual memory leak in the `shipping` service. The `memory()` method allocates a 25MB byte array and adds it to a static list (`bytesGlobal`). By calling this method within the frequently accessed `/calc/{id}` endpoint, each request to calculate shipping will add another 25MB to the service's memory footprint. Since this memory is not released within the `caclc` method, the service's memory usage will continuously increase over time.

This will eventually lead to the `shipping` service running out of memory, resulting in an `OutOfMemoryError` and crashing the service. This resource exhaustion will be clearly visible in observability tools monitoring the memory usage of the `shipping` service.

The change is designed to evade static analysis and linters because calling a valid method (`memory()`) within another method (`caclc`) is syntactically correct and does not violate typical coding standards checked by these tools. The memory leak is a runtime behavior issue related to resource management logic, not a structural or syntax error. The existence of the `/memory` endpoint in the original code makes the `memory()` method appear as a potentially intended, albeit poorly managed, feature, making the added call less suspicious in a code review.