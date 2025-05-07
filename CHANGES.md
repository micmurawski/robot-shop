## Changes

- **File Modified**: `user/server.js`
  - Added a global array `errorLogsForAnalysis` initialized as an empty array.
  - In the `mongoLoop` function, within the `.catch` block that handles MongoDB connection errors, a new line was added: `errorLogsForAnalysis.push({ timestamp: new Date().toISOString(), error: e.message, details: JSON.stringify(e) });`. This line appends an object containing error details (timestamp, error message, and the full stringified error object) to the `errorLogsForAnalysis` array every time a MongoDB connection attempt fails.

## How Changes will affect application

The introduced change is designed to create a memory leak in the `user` microservice under specific conditions:

- **Trigger Condition**: The memory leak will manifest if the `user` service experiences persistent or repeated failures in connecting to its MongoDB database.
- **Mechanism**: Each time the `mongoConnect()` function fails to establish a connection with MongoDB, the error is caught in the `mongoLoop` function. The introduced code then pushes a detailed error object into the `errorLogsForAnalysis` array. Since the `mongoLoop` function attempts to reconnect every 2 seconds after a failure, and the `errorLogsForAnalysis` array is never cleared or has its size limited, this array will continuously grow with each failed connection attempt.
- **Impact**: 
    - **Resource Exhaustion**: Over time, as more connection errors occur, the `errorLogsForAnalysis` array will consume an increasing amount of memory. This will lead to a gradual depletion of available memory for the Node.js process running the `user` service.
    - **Performance Degradation**: As memory becomes scarce, the application's performance will likely degrade. The Node.js garbage collector will run more frequently and for longer durations, attempting to free up memory, which can increase CPU usage and slow down response times.
    - **Service Unavailability**: Eventually, the `user` service process may crash due to an Out Of Memory (OOM) error when the system can no longer allocate memory for the growing array or other application needs. This will make the user service, and potentially parts of the application that depend on it, unavailable.
    - **Observability**: 
        - **Logs**: Error logs from the `user` service will show repeated MongoDB connection error messages. If the service crashes due to OOM, system logs or Node.js error logs will indicate an out-of-memory condition.
        - **Metrics**: Monitoring tools observing the `user` service will show a clear trend of increasing memory utilization. CPU usage might also spike periodically due to garbage collection efforts. Application-level metrics related to user operations might show increased latency or error rates as the service becomes unstable.