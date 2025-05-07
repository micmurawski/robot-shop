## Changes

- **shipping/src/main/java/com/instana/robotshop/shipping/Controller.java**
    - Added a call to the `memory()` method within the `caclc(@PathVariable long id)` method.

```java
    @GetMapping("/calc/{id}")
    public Ship caclc(@PathVariable long id) {
        double homeLatitude = 51.164896;
        double homeLongitude = 7.068792;

        logger.info("Calculation for {}", id);

        City city = cityrepo.findById(id);
        if (city == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "city not found");
        }

        Calculator calc = new Calculator(city);
        long distance = calc.getDistance(homeLatitude, homeLongitude);
        // avoid rounding
        double cost = Math.rint(distance * 5) / 100.0;
        Ship ship = new Ship(distance, cost);
        logger.info("shipping {}", ship);

        // Introduce memory leak here
        memory(); // <--- ADDED THIS LINE

        return ship;
    }
```

## How Changes will affect application

The introduced change in the `caclc` method of the Shipping service will cause a memory leak. Each time the `/calc/{id}` endpoint is called to calculate shipping costs, the `memory()` method will be executed. This method allocates a 25MB byte array and adds it to a static list (`bytesGlobal`). Since this list is not cleared within the `caclc` method's execution flow, the memory consumed by the Shipping service will continuously increase with every shipping calculation request.

This continuous memory allocation without deallocation will eventually exhaust the Java Virtual Machine's heap space, leading to an `OutOfMemoryError`. This error will cause the Shipping service to become unstable, potentially leading to slow responses, frozen requests, and eventually crashing. The increasing memory usage will be visible in resource monitoring tools, and the `OutOfMemoryError` will be present in the service's logs, providing clear indicators for on-call engineers to investigate and diagnose the problem. The impact will be most pronounced under sustained load on the shipping calculation endpoint.