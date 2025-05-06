```markdown
# Runtime Error Introduction Documentation

This document details the subtle modifications introduced into the Robot Shop microservices codebase to cause runtime errors under specific conditions. These changes are designed to pass compilation, build processes, and static analysis tools, manifesting only during program execution.

## Modified Files and Introduced Errors

### `shipping/src/main/java/com/instana/robotshop/shipping/Controller.java`

This file contains the Spring Boot controller for the Shipping service. Modifications were made to introduce resource management and edge case handling issues.

#### Modification 1: Integer Overflow in Memory Allocation

*   **Change:** The `/memory` endpoint was modified to accept an integer path variable `size`. The memory allocation line `byte[] bytes = new byte[1024 * 1024 * 25];` was changed to `byte[] bytes = new byte[size * 1024 * 1024];`.
*   **Runtime Error Triggered:** `NegativeArraySizeException`. If a large enough integer `size` is provided (e.g., a value that, when multiplied by 1024\*1024, exceeds `Integer.MAX_VALUE`), the multiplication will result in an integer overflow, producing a negative number. Attempting to create a byte array with a negative size is illegal and throws this exception at runtime.
*   **Application Impact:** A request to the `/memory` endpoint with a large size parameter will cause the Shipping service instance handling the request to crash with a `NegativeArraySizeException`. This could lead to service unavailability or unexpected behavior if not properly handled by the surrounding infrastructure (like Kubernetes restarting the pod).
*   **Why it Evades Static Analysis:** Static analysis tools check for syntactic correctness and common programming errors. The code `new byte[allocationSize]` is syntactically valid Java. The potential for `allocationSize` to become negative due to integer overflow depends on the runtime input (`size`) and the specific values involved in the multiplication, which static analysis typically does not evaluate.

#### Modification 2: Data-Dependent Error in City Matching

*   **Change:** A condition was added to the `/match/{code}/{text}` endpoint's `match` method: `else if (text.equalsIgnoreCase("error")) { throw new RuntimeException("Simulated error for specific input"); }`.
*   **Runtime Error Triggered:** `RuntimeException`. When the `text` path variable is provided as the string "error" (case-insensitive), the code explicitly throws a `RuntimeException`.
*   **Application Impact:** If a user searches for a city using the term "error" in the shipping form's auto-complete functionality, the frontend will receive a 500 Internal Server Error from the Shipping service, and the auto-complete will fail to provide suggestions. This disrupts the user flow for selecting a shipping location.
*   **Why it Evades Static Analysis:** This error is triggered by a specific string value provided as input. Static analysis tools do not typically analyze the semantic meaning of input data or execute code paths based on specific string comparisons like `"error"`. The structure of an `if` statement throwing an exception is valid Java code.

#### Modification 3: Edge Case Failure for Specific City ID

*   **Change:** A condition was added to the `/calc/{id}` endpoint's `caclc` method: `else if (city.getUuid() == 1337) { throw new RuntimeException("Simulated calculation error for city ID 1337"); }`.
*   **Runtime Error Triggered:** `RuntimeException`. When a request is made to calculate shipping for a city with the UUID `1337`, the code explicitly throws a `RuntimeException`.
*   **Application Impact:** If a user selects a city with the UUID 1337 during the shipping process, the application will fail to calculate the shipping cost, preventing the user from proceeding to the payment step. This will likely manifest as an error message or unresponsive UI on the frontend.
*   **Why it Evades Static Analysis:** This is a data-dependent logical error based on a specific numerical ID (`1337`). Static analysis tools do not track specific data values like database record IDs through the application logic. The code structure (an `if` statement throwing an exception) is valid Java.

### `cart/server.js`

This file contains the Node.js/Express server for the Cart service. A modification was made to introduce a subtle data processing issue.

#### Modification: Floating-Point Precision Issue in Tax Calculation

*   **Change:** The `calcTax` function was modified from `return (total - (total / 1.2));` to `return Math.round(total * 0.2 * 100) / 100;`.
*   **Runtime Error Triggered:** Subtle logical error due to floating-point precision and rounding differences. The original code calculates tax by subtracting the pre-tax amount (`total / 1.2`) from the total. The new code calculates 20% of the total directly and then rounds the result to two decimal places. While both aim for 20% tax, floating-point arithmetic can introduce small discrepancies. For certain `total` values, the result of `(total - (total / 1.2))` might differ slightly from `Math.round(total * 0.2 * 100) / 100` due to how floating-point numbers are represented and calculated, leading to incorrect tax amounts in specific scenarios. This is a data-dependent logical error rather than a crash.
*   **Application Impact:** The calculated tax amount displayed to the user and potentially used in subsequent payment processing might be slightly incorrect for certain cart totals. This could lead to minor financial discrepancies or fail tests that expect exact tax values based on the original calculation method.
*   **Why it Evades Static Analysis:** Both arithmetic expressions are syntactically valid JavaScript. Static analysis tools do not analyze the nuances of floating-point arithmetic precision or compare the results of different valid mathematical formulas to determine business logic correctness.

### `user/server.js`

This file contains the Node.js/Express server for the User service. A modification was made to introduce a logical error in the authentication process.

#### Modification: Password Length-Based Login Failure

*   **Change:** A condition was added within the successful login block of the `/login` endpoint: `if (req.body.password.length === 8 && user.name !== 'stan') { req.log.warn('login failed due to specific password length'); res.status(404).send('incorrect password'); } else { res.json(user); }`.
*   **Runtime Error Triggered:** Logical Error / Incorrect Authentication. This modification introduces a hidden condition where users (except for the user 'stan') whose correct password happens to be exactly 8 characters long will fail to log in. The service will return a "404 incorrect password" error, even though the provided password is correct and matches the one stored for the user.
*   **Application Impact:** Users with 8-character passwords (excluding 'stan') will be unable to log in to the application, receiving an incorrect password error message on the frontend. This disrupts the login functionality for a specific subset of users.
*   **Why it Evades Static Analysis:** This is a complex logical condition based on the runtime value of the password string's length and the username. Static analysis tools do not typically evaluate string lengths or compare specific string values (`'stan'`) in this manner to identify incorrect authentication logic. The code is syntactically valid JavaScript, using standard control flow and string properties.

### `web/static/js/controller.js`

This file contains the AngularJS controller for the web frontend. A modification was made to introduce a logical error in cart item processing.

#### Modification: Incorrect Indexing for Shipping Item Removal

*   **Change:** In the `loadCart` function within the `cartform` controller, the logic to check for and potentially remove the shipping item was changed from checking the *last* item (`cart.items[cart.items.length - 1]`) to checking the *first* item (`cart.items[0]`).
*   **Runtime Error Triggered:** Logical Error / Incorrect Cart State Management. The application logic intends to remove a temporary shipping item that is added to the end of the cart during the shipping calculation process. By changing the index check from the last item to the first item, the code will fail to identify and remove the shipping item unless it coincidentally happens to be the very first item in the cart. This will result in the shipping item remaining in the cart, leading to an inflated total cost. It could also potentially attempt to remove a non-shipping item if it happens to be the first item and its SKU is 'SHIP'.
*   **Application Impact:** The cart total displayed to the user after the shipping calculation step will be incorrect, as the temporary shipping item will not be removed. This will lead to the user being charged an incorrect amount during the payment process.
*   **Why it Evades Static Analysis:** This change involves modifying an array index. Static analysis tools can verify that the index is a valid integer, but they cannot understand the intended logic of checking the last element versus the first element or predict the runtime order and contents of the `cart.items` array. The code is syntactically valid JavaScript.

```