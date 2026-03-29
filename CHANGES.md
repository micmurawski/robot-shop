## Incident Response Training Exercise: Introduce Memory Leak in User Service

This change introduces a controlled memory leak in the `user` microservice for an incident response training exercise.

### Changes

1.  **File Modified:** `user/server.js`
2.  **Global Cache for "Sessions":**
    *   Added a global JavaScript object named `activeSessionsCache`.
    *   Added a global counter `sessionIdCounter` initialized to `0`.
3.  **Modification to `/uniqueid` Endpoint:**
    *   On every GET request to `/api/user/uniqueid`:
        *   The `sessionIdCounter` is incremented.
        *   A new `sessionRecord` object is created. This object stores:
            *   `timestamp`: Current time.
            *   `userAgent`: User-Agent header from the request.
            *   `ip`: IP address of the requester.
            *   `assignedId`: The unique ID generated (e.g., `anonymous-123`).
            *   `activityLog`: An array of 500 strings (to increase memory footprint per session).
        *   This `sessionRecord` is added to the `activeSessionsCache` using the `sessionIdCounter` as the key.
    *   **Crucially, entries added to `activeSessionsCache` are never removed.**

```javascript
// Global store, intended for "active session tracking", but will leak
const activeSessionsCache = {};
let sessionIdCounter = 0; // To generate unique keys for the cache

// ... inside the /uniqueid endpoint handler ...
app.get('/uniqueid', (req, res) => {
    redisClient.incr('anonymous-counter', (err, r) => {
        sessionIdCounter++; // Increment for each request to create a new key
        if(!err) {
            const uniqueId = 'anonymous-' + r;
            // Store some "session info" associated with the request, but never clean it up.
            const sessionRecord = {
                timestamp: Date.now(),
                userAgent: req.headers['user-agent'],
                ip: req.ip,
                assignedId: uniqueId,
                activityLog: Array(500).fill(`log_entry_for_session_${sessionIdCounter}_id_${uniqueId}`)
            };
            activeSessionsCache[sessionIdCounter] = sessionRecord;

            res.json({
                uuid: uniqueId
            });
        } else {
            req.log.error('ERROR', err);
            res.status(500).send(err);
        }
    });
});
```

### How Changes Affect Application

*   **Memory Leak in `user` Service:** Each call to the `/api/user/uniqueid` endpoint will now cause the `user` service to consume a small amount of additional memory that is never reclaimed. The `load-gen/robot-shop.py` script, which simulates user traffic, makes requests that result in calls to this endpoint to generate IDs for anonymous users.
*   **Progressive Memory Exhaustion:** Over time, as the `load-gen` script runs and real users (in a testing scenario) interact with the application, the `activeSessionsCache` in the `user` service will grow indefinitely. This will lead to a steady increase in the memory footprint of the `user` service's Node.js process.
*   **Observable Symptoms:**
    *   **Increased Memory Usage:** Monitoring tools will show rising memory consumption for the `user` service container/pod.
    *   **Performance Degradation:** As memory becomes scarce, the Node.js garbage collector will run more frequently and for longer durations, potentially leading to increased latency and degraded performance for all `user` service endpoints.
    *   **Out Of Memory (OOM) Errors:** Eventually, the `user` service process is likely to crash due to an OOM error. This will make the `user` service unavailable.
*   **Impact on Dependent Services:**
    *   The `web` service relies on the `user` service for functionalities like generating unique IDs for guest sessions and user login/registration. When the `user` service becomes slow or crashes, these features on the `web` frontend will fail or become very slow.
    *   Any other service that might directly or indirectly (e.g., through the `web` service) rely on user identification or session management provided by the `user` service will be affected.
*   **Trigger Condition:** The memory leak is reliably triggered by the `load-gen/robot-shop.py` script as it simulates new users, each requiring a unique ID.
*   **Stealthiness:** The change passes compilation and static analysis because adding to a cache is a legitimate operation. The error is a runtime issue due to the *absence* of a cache eviction strategy in this specific code path, which is hard for static tools to detect as an intentional flaw.