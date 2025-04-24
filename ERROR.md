Here's the ERROR.md content for the injected error:

```markdown
# Error Documentation

This document contains details about errors intentionally injected into the codebase for testing and educational purposes. It was generated on [current date].

## 1. Logic Error in Ship.java

### File Path
shipping/src/main/java/com/instana/robotshop/shipping/Ship.java

### Line Number
38

### Error Type
Logic error

### Description
A logic error was introduced in the toString() method where the distance and cost are swapped in the output string. This will cause incorrect display of shipping information, potentially leading to confusion or errors in downstream processes that rely on this string representation.

### Original Code
```java
return String.format("Distance: %d Cost: %f", distance, cost);
```

### Modified Code with Error
```java
return String.format("Distance: %f Cost: %d", cost, distance);
```

This error swaps the positions of `distance` and `cost` in the formatted string, and also mismatches the format specifiers (`%d` for integer and `%f` for float) with the variable types. As a result, the output will display the cost where the distance should be and vice versa, with incorrect formatting.
```