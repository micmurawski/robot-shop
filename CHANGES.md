## Changes

- Modified the `getProduct` function in `cart/server.js`.
- Introduced a conditional statement within the `getProduct` function:
  - If the input `sku` is exactly `'FAIL_PRODUCT_LOOKUP_001'`, the `currentCatalogueHost` variable is intentionally set to an invalid and unreachable hostname: `'force-error-catalogue.service.local'`.
  - For all other SKUs, `currentCatalogueHost` defaults to the standard `catalogueHost`.
- The subsequent HTTP request to the catalogue service for product details uses the `currentCatalogueHost`.

## How Changes will affect application

- **Targeted Runtime Error:** The application will function normally for all product interactions except when a user attempts to add the product with SKU `'FAIL_PRODUCT_LOOKUP_001'` to their cart.
- **Communication Failure:** When this specific SKU is processed by the cart service, the `getProduct` function will attempt to make an HTTP request to `http://force-error-catalogue.service.local:8080/product/FAIL_PRODUCT_LOOKUP_001`.
  - This will result in a network error, such as a DNS resolution failure (as the hostname is invalid) or a connection timeout.
- **User Experience:** The user attempting to add the product `'FAIL_PRODUCT_LOOKUP_001'` to the cart will likely encounter an error. The UI might display a "product not found" message or a generic error indicating the item could not be added.
- **Error Logging & Observability:**
  - The `cart` service logs will record errors related to the failed network request (e.g., `ENOTFOUND`, `ETIMEDOUT`).
  - Observability tools should indicate an increased error rate for the `/api/cart/add/:id/:sku/:qty` endpoint when the problematic SKU is used.
  - Metrics might show DNS resolution errors or connection timeouts originating from the `cart` service.
- **Stealthiness:**
  - The change is syntactically correct and will pass compilation, build processes, and linters.
  - It's a data-dependent logical error, making it hard for static analysis tools to detect.
  - During a code review, it might be misinterpreted as a test hook, a placeholder for a future feature, or an unconventional way to handle a specific product, rather than a deliberate error introduction.