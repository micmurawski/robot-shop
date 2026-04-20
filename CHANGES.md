## Incident Response Training Exercise: Dispatch Service Memory Leak

This document outlines the changes made to the `dispatch` microservice to introduce a controlled failure scenario for an incident response training exercise.

### Changes

The following modifications were made to the `dispatch/main.go` file:

1.  **Global Variable Addition:**
    *   A new global variable `processedOrderCache` was declared and initialized as an empty map:
        ```go
        processedOrderCache = make(map[string]time.Time)
        ```

2.  **Modification in `getOrderId` Function:**
    *   Inside the `getOrderId` function, after successfully extracting the `orderid` from the incoming message, a new line was added to store the `orderid` and the current timestamp into the `processedOrderCache` map:
        ```go
        // Simulate caching the order ID with a timestamp, leading to a leak
        processedOrderCache[id] = time.Now()
        ```

### How Changes Affect Application

This introduced change is designed to simulate a **memory leak** (Resource Exhaustion) in the `dispatch` service. Here's how it will affect the microservice application:

1.  **Runtime Error & Conditions:**
    *   As the `dispatch` service processes incoming orders from RabbitMQ, each unique `orderid` will be added as a key to the `processedOrderCache` map along with the current timestamp.
    *   Crucially, there is no mechanism implemented to remove entries from this `processedOrderCache`.
    *   Consequently, the map will grow indefinitely with every new order processed, leading to a continuous increase in the memory footprint of the `dispatch` service.
    *   This error will only manifest at runtime and will become more pronounced as the `load-gen/robot-shop.py` script generates more orders.

2.  **Observable Symptoms:**
    *   **Increasing Memory Usage:** The primary symptom will be a steady and observable increase in the memory consumed by the `dispatch` service's container/pod. This can be monitored using tools like `docker stats`, Kubernetes metrics (`kubectl top pod`), or other APM solutions.
    *   **Performance Degradation:** As memory becomes scarce, the Go runtime will spend more time on garbage collection (GC). This can lead to increased CPU usage and longer GC pauses, resulting in higher processing latency for dispatch operations.
    *   **Out Of Memory (OOM) Errors:** Eventually, the `dispatch` service will exhaust the available memory allocated to its container/pod. This will likely result in the operating system's OOM killer terminating the process, or the Go runtime itself panicking with an out-of-memory error. Logs from the container (e.g., `fatal error: runtime: out of memory`) or Kubernetes events will indicate this.
    *   **Service Unresponsiveness/Crashes:** Before a full OOM kill, the service might become unresponsive or frequently restart.
    *   **RabbitMQ Queue Buildup:** If the `dispatch` service slows down significantly or crashes, it will stop consuming messages from the `orders` queue in RabbitMQ at the normal rate. This will lead to a buildup of messages in the queue, which can be observed via RabbitMQ's management interface or metrics.

3.  **Why Static Analysis Won't Detect This:**
    *   The code change itself (adding an item to a map) is a syntactically correct and common programming pattern.
    *   Static analysis tools primarily check for syntax errors, type issues, and known anti-patterns detectable without executing the code. They cannot typically predict runtime behavior that depends on data flow and the absence of data eviction logic over time.
    *   The issue is a *logical flaw* in data management (an unbounded cache) rather than a static code defect.

4.  **Troubleshooting Techniques for Identification:**
    *   **Metrics Monitoring:** Observing memory usage trends over time is the most direct way to spot a leak.
    *   **Profiling:** Using Go's `pprof` tool (specifically heap profiling) would reveal that the `processedOrderCache` map is growing and retaining a large number of objects.
    *   **Log Analysis:** Correlating OOM error messages or service restart logs with periods of high load.
    *   **Focused Code Review:** Once symptoms point to a memory issue in `dispatch`, reviewing how it stores and manages data in memory would lead to the `processedOrderCache`.