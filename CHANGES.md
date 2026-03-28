## Changes

- **Modified File:** `web/static/js/controller.js`
- **Details:**
    - In the `shopform` controller, within the `$scope.getProducts` function, a conditional block was added.
    - This block executes a computationally intensive `for` loop (iterating 200,000,000 times with mathematical operations) specifically when the `category` parameter is "Robot".
    - Console log messages have been added to indicate the start and end of this intensive processing block.

```javascript
// ...
$scope.getProducts = function(category) {
    if($scope.data.products[category]) {
        $scope.data.products[category] = null;
    } else {
        $http({
            url: '/api/catalogue/products/' + category,
            method: 'GET'
        }).then((res) => {
            if (category === 'Robot') { // <-- ADDED CONDITION
                // ADDED BLOCK START
                console.log('Performing intensive client-side processing for Robot category products...');
                let sum = 0;
                for (let i = 0; i < 200000000; i++) { 
                    sum += Math.sqrt(i) * Math.sin(i) / Math.cos(i);
                }
                console.log('Client-side processing complete for Robot category. Result (unused): ' + sum);
                // ADDED BLOCK END
                $scope.data.products[category] = res.data;
            } else {
                $scope.data.products[category] = res.data;
            }
        }).catch((e) => {
            console.log('ERROR', e);
        });
    }
};
// ...
```

## How Changes Affect Application

This change introduces a client-side performance issue, specifically a **CPU resource exhaustion** scenario within the user's web browser.

1.  **Trigger Condition:** The issue manifests when a user on the Robot Shop website clicks to expand the "Robot" product category on the main shop page. This action calls the modified `$scope.getProducts` function with `category` equal to "Robot".
2.  **Immediate Effect:** Upon triggering, the browser will execute the computationally intensive loop. This will cause the CPU usage for that browser tab/process to spike significantly on the client's machine.
3.  **Observable Symptoms:**
    *   The user will experience a noticeable slowdown or unresponsiveness in the browser tab where the Robot Shop application is running. The page might freeze or become very sluggish for the duration of the loop's execution.
    *   Client machine's overall CPU usage will increase, potentially impacting other applications running on the user's system.
    *   Browser developer tools (if open) will show console messages indicating the start and completion of the "intensive client-side processing". The Performance tab in developer tools would clearly show a long-running JavaScript task consuming CPU resources.
4.  **Server-Side Impact:** There will be no direct errors or significant load increase on the server-side components (like the `catalogue` service or `web` server itself) due to this change. The `catalogue` service will successfully return the product data for the "Robot" category. The issue is purely client-side, occurring after the data is received by the browser.
5.  **Training Scenario:** This change simulates a scenario where inefficient or overly complex client-side JavaScript code (perhaps introduced accidentally during development or due to complex data processing logic) leads to a poor user experience and resource exhaustion on the end-user's device. It will allow the on-call team to practice diagnosing issues that are not immediately apparent from server-side logs or metrics, requiring them to investigate client-side behavior.