# Changes

The following change was introduced in the `ratings` microservice:

*   **File:** `ratings/html/src/Controller/RatingsApiController.php`
*   **Method:** `put(Request $request, string $sku, int $score): Response`
*   **Modification:** The line responsible for updating the rating count when an existing product rating is updated was changed.
    *   Original line: `$this->ratingsService->updateRatingForSKU($sku, $newAvg, $rating['rating_count'] + 1);`
    *   Modified line: `$this->ratingsService->updateRatingForSKU($sku, $newAvg, $rating['rating_count']);`

This change means that when a product's rating is updated (i.e., it's not the first rating for that product), the `rating_count` in the database is updated with its existing value instead of being incremented.

# How Changes Affect Application

This modification introduces a logical error in the rating update mechanism.

*   **Runtime Error:** When a user submits a rating for a product that has already been rated at least once, the `rating_count` for that product in the database will not be incremented. While the `$newAvg` (new average rating) is calculated correctly using `($rating['rating_count'] + 1)` as the divisor (anticipating an incremented count), the subsequent call to `updateRatingForSKU` passes the *old*, unincremented `$rating['rating_count']` to be stored in the database. 
    As a result, the `rating_count` for a product will effectively get stuck at the value it had before this erroneous update (or 1, if it was the first update after an initial rating). Subsequent average rating calculations will use this incorrect, stale `rating_count`. This will lead to the displayed average rating being inaccurate and increasingly skewed, as it will be calculated based on a denominator that does not reflect the true number of ratings received.

*   **Impact on Observability:**
    *   Users may report that product average ratings are incorrect or behave erratically, especially for frequently rated items.
    *   Metrics tracking average product ratings might show values that don't align with the number of reviews or individual scores.
    *   Error logs might not directly pinpoint this line of code. Instead, on-call engineers might observe data inconsistencies in the `ratings` table (e.g., `rating_count` not increasing despite new ratings being processed) or unexpected behavior in how average ratings are calculated and displayed. Debugging will be required to trace the issue back to this logical flaw in the `rating_count` update.

*   **Why Static Analysis and Linters Won't Detect It:**
    *   The change is a purely logical error. The PHP code remains syntactically valid and does not violate any type rules or common linting rules.
    *   Static analysis tools are unlikely to understand the intended business logic of how an average rating and its count should be maintained.
    *   The modification is subtle (removal of `+ 1`) and could be overlooked in a code review if the reviewer is not deeply familiar with the specific logic of the rating calculation and update process. It might appear as an intentional, albeit incorrect, refactoring.