## Changes

- **File Modified:** `mongo/catalogue.js`
- **Modification Details:** The `description` field for the product with `sku: 'Watson'` has been significantly enlarged. An 8MB string (consisting of repeated period characters) was appended to the original description.

## How Changes will affect application

This modification is designed to introduce a **Resource Exhaustion (Memory)** issue, specifically within the **catalogue service**.

1.  **Triggering the Error:** When the catalogue data is initialized from `mongo/catalogue.js`, or more critically, when a user or another service requests the product details for "Watson" (SKU: `Watson`), the `catalogue` service will attempt to load this product entry, including its now extremely large (8MB+) description, into memory.

2.  **Impact on Catalogue Service:**
    *   The Node.js runtime, which powers the `catalogue` service, has a default heap memory limit. Loading such a large string for a single product, especially if multiple requests for this product occur concurrently, can quickly consume the available heap space.
    *   This is highly likely to lead to the `catalogue` service crashing with an `OutOfMemoryError` or becoming unresponsive/extremely slow due to excessive garbage collection efforts.

3.  **Observability:**
    *   Error logs indicating memory exhaustion (e.g., `FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory`) should become visible in the `catalogue` service's logs.
    *   Monitoring tools should show a sharp increase in memory usage for the `catalogue` service pods/containers, followed by restarts if the process crashes.

4.  **Evasion of Static Analysis:**
    *   The change is made within a data seeding script (`.js` file for MongoDB) and not in the core application logic of the microservices.
    *   The JavaScript syntax `'.'.repeat(8 * 1024 * 1024)` used to generate the large string is perfectly valid. Static analysis tools for the application code (Node.js, Java, etc.) would not flag this as an error, as they typically don't analyze the semantic meaning or potential runtime impact of data values within seed scripts.
    *   The error only manifests at runtime when the data is loaded and processed by a service with finite memory resources.