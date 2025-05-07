# Runtime Error Introduction: IndexOutOfBoundsException in Shipping Service

## Changes

1.  **File Modified**: `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`
    *   In the `match` method, the logic for truncating the `cities` list, when its size is greater than 10, was altered.
    *   **Original line**:
        ```java
        cities = cities.subList(0, 9);
        ```
    *   **Modified line**:
        ```java
        cities = cities.subList(1, cities.size() + 1);
        ```

## How Changes will affect application

This modification introduces a latent `IndexOutOfBoundsException` in the `shipping` service.

*   **Error Trigger**: The error will occur when the `GET /match/{code}/{text}` endpoint is called, and the number of cities returned by the database query (`cityrepo.match(code, text)`) is greater than 10.
*   **Mechanism**: 
    *   If `cities.size()` is, for example, 11, the modified code `cities.subList(1, cities.size() + 1)` becomes `cities.subList(1, 12)`.
    *   `List.subList(fromIndex, toIndex)` requires `toIndex` to be less than or equal to `list.size()`.
    *   In this case, `toIndex` (12) will be greater than `cities.size()` (11), leading to an `IndexOutOfBoundsException` (or `IllegalArgumentException` depending on the exact List implementation, though typically `IndexOutOfBoundsException` for `toIndex > size()`).
*   **Impact**: 
    *   When triggered, the `/match/{code}/{text}` request will fail with a HTTP 500 Internal Server Error.
    *   An `IndexOutOfBoundsException` (or similar) stack trace will be logged by the `shipping` service, which should be visible in application performance monitoring (APM) and logging tools.
*   **Stealthiness**: 
    *   The code compiles successfully as the syntax is valid.
    *   Static analysis tools are unlikely to flag this as an error because it depends on the runtime size of the `cities` list, which is not known at compile time.
    *   The change might appear as a legitimate, albeit incorrect, attempt to adjust the sublist range, potentially passing a cursory code review if not scrutinized carefully for off-by-one errors in boundary conditions.