## Changes

- **File Modified**: `ratings/html/src/Controller/RatingsApiController.php`

- **Logic Added**: 
  - In the `put` method (handles `PUT /api/rate/{sku}/{score}` requests):
    - A conditional block was introduced that checks if the `sku` parameter is equal to "Watson".
    - If the condition is met (i.e., the product being rated is "Watson"), a `sleep(2);` function call is executed, introducing a 2-second delay.
    - A log message `Simulated processing delay for SKU: {$sku}` is now emitted to the logger if the delay is triggered.

```php
// ...
    public function put(Request $request, string $sku, int $score): Response
    {
        $score = min(max(1, $score), 5);

        if ($sku === 'Watson') { // <<<------ ADDED CONDITION
            sleep(2);            // <<<------ ADDED DELAY
            if (null !== $this->logger) { // <<<------ ADDED LOGGING
                $this->logger->info("Simulated processing delay for SKU: {$sku}"); // <<<------ ADDED LOGGING
            }
        }

        try {
// ...
```

## How Changes Affect Application

This change introduces a controlled latency issue specifically within the **ratings microservice**. 

1.  **Targeted Performance Degradation**: 
    - When a user or an automated script (like `load-gen/robot-shop.py`) attempts to submit a rating for the product with SKU "Watson", the API endpoint `/api/ratings/api/rate/Watson/{score}` will now take approximately 2 seconds longer to respond.
    - Ratings for any other product SKUs will remain unaffected and will be processed without this artificial delay.

2.  **Observable Symptoms**:
    - **Increased Latency Metrics**: Monitoring tools (e.g., APM solutions) will show a clear spike in response time for the `PUT /api/ratings/api/rate/...` endpoint specifically when the SKU is "Watson". Average and percentile latencies for this specific transaction will increase.
    - **Log Entries**: The ratings service logs will contain the message `Simulated processing delay for SKU: Watson` whenever the delay is triggered, providing a direct clue during troubleshooting.
    - **Potential Upstream Impact**: 
        - The **web service**, which calls the ratings service, might experience slower responses when a user rates the "Watson" product. If the web service has client-side timeouts for API calls that are shorter than the induced delay plus normal processing time, this could lead to user-facing errors or sluggishness.
        - Other services or automated tests interacting with the rating functionality for "Watson" will also observe this delay.

3.  **Runtime Detection**: 
    - The issue will **not** be caught by static analysis, compilation, or build processes because `sleep()` is a valid PHP function and the condition is based on runtime data.
    - The failure is designed to manifest only during runtime when the specific conditions (rating product "Watson") are met.

4.  **Incident Response Training**: 
    - This change is intended for an incident response training exercise. On-call engineers will be expected to observe the symptoms (latency, logs), use troubleshooting tools (APM, distributed tracing, log analysis) to diagnose that the ratings service is the source of the delay, and pinpoint the cause to the specific handling of the "Watson" SKU.