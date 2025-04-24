Here's the ERROR.md content for the injected error:

```markdown
# Error Documentation

This document provides details about errors that were intentionally injected into the codebase for testing and educational purposes. It was generated on [current date].

## Error 1: Resource Exhaustion

### File Path
shipping/src/main/java/com/instana/robotshop/shipping/ShippingServiceApplication.java

### Line Number
70

### Error Type
Resource exhaustion

### Description
This error introduces a potential memory leak by creating a new Random object for each request. Over time, this could lead to increased memory usage and potential OutOfMemoryError.

### Original Code
```java
SpanSupport.annotate("datacenter", DATA_CENTERS[new Random().nextInt(DATA_CENTERS.length)]);
```

### Modified Code with Error
```java
SpanSupport.annotate("datacenter", DATA_CENTERS[new Random(System.currentTimeMillis()).nextInt(DATA_CENTERS.length)]);
```

The modification creates a new Random object seeded with the current system time for each request, potentially leading to unnecessary object creation and memory usage over time.
```