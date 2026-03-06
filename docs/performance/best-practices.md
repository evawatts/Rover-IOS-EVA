# Performance Best Practices

This guide provides actionable recommendations for optimizing Rover 5 SDK performance in your iOS applications. Follow these practices to minimize impact on app performance while maximizing analytics value.

## Initialization Best Practices

### 1. Initialize Early, But Not Too Early

```swift
// ✅ Good: Initialize in applicationDidFinishLaunching
func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Do critical app setup first
    setupCoreServices()
    
    // Initialize Rover after core setup
    setupRover()
    
    return true
}

private func setupRover() {
    rover = Rover(configuration: RoverConfiguration(
        apiKey: "your-api-key"
    ))
}
```

```swift
// ❌ Avoid: Don't initialize too early
func application(_ application: UIApplication, 
                willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Too early - may delay critical app setup
    rover = Rover(configuration: RoverConfiguration(apiKey: "key"))
    return true
}
```

### 2. Use Environment-Specific Configurations

```swift
private func createRoverConfiguration() -> RoverConfiguration {
    #if DEBUG
    return RoverConfiguration(
        apiKey: developmentAPIKey,
        debugMode: true,
        batchSize: 5,        // Smaller batches for immediate feedback
        flushInterval: 10    // More frequent uploads for testing
    )
    #else
    return RoverConfiguration(
        apiKey: productionAPIKey,
        debugMode: false,
        batchSize: 30,       // Larger batches for efficiency
        flushInterval: 60    // Less frequent uploads to save battery
    )
    #endif
}
```

## Event Tracking Optimization

### 1. Choose Appropriate Event Categories

Different categories have different performance characteristics:

```swift
// ✅ Functional events: Lightweight, essential for app analytics
rover.track(name: "Screen Viewed", category: .functional)
rover.track(name: "App Opened", category: .functional)

// ✅ Tracking events: Higher overhead, use for user interactions
rover.track(name: "Button Tapped", category: .tracking)
rover.track(name: "Purchase Completed", category: .tracking)
```

**Performance Impact:**
- **Functional events**: ~2ms processing time
- **Tracking events**: ~4ms processing time

### 2. Optimize Event Properties

```swift
// ✅ Good: Lean, essential properties
rover.track(name: "Product Viewed", properties: [
    "product_id": "123",
    "category": "electronics",
    "price": 299.99
])

// ❌ Avoid: Excessive nested data
rover.track(name: "Product Viewed", properties: [
    "product_id": "123",
    "full_product_data": productObject,  // Large object
    "user_profile": userProfile,         // Large nested data
    "session_history": sessionHistory    // Large array
])
```

**Property Guidelines:**
- Keep properties flat when possible
- Limit to 10-15 properties per event
- Use primitive types (String, Int, Double, Bool)
- Avoid large nested objects

### 3. Use Auto-Classification When Appropriate

```swift
// ✅ Let the SDK classify common events
rover.track(name: "App Opened")      // Auto: .functional
rover.track(name: "Button Tapped")   // Auto: .tracking
rover.track(name: "Screen Viewed")   // Auto: .functional

// ✅ Explicit category for custom events
rover.track(name: "Custom Workflow Step", category: .functional)
```

Auto-classification adds ~1ms overhead but simplifies code and reduces errors.

## Batching and Network Optimization

### 1. Configure Batching for Your Use Case

```swift
// High-volume apps (1000+ events/hour)
let highVolumeConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 50,        // Larger batches
    flushInterval: 120    // Less frequent uploads
)

// Real-time apps (chat, gaming)
let realTimeConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 5,         // Smaller batches
    flushInterval: 15     // More frequent uploads
)

// Standard apps (typical usage)
let standardConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 20,        // Balanced
    flushInterval: 30     // Default
)
```

### 2. Use Manual Flushing Strategically

```swift
// ✅ Good: Flush at natural breakpoints
func applicationDidEnterBackground(_ application: UIApplication) {
    rover.flush()  // Ensure events are sent before backgrounding
}

func userDidCompleteCheckout() {
    rover.track(name: "Purchase Completed", category: .tracking)
    rover.flush()  // Important conversion event - send immediately
}

// ❌ Avoid: Excessive manual flushing
func buttonTapped() {
    rover.track(name: "Button Tapped", category: .tracking)
    rover.flush()  // Unnecessary - let batching handle this
}
```

### 3. Network-Aware Configuration

```swift
// Monitor network conditions and adjust
func configureForNetworkConditions() {
    let reachability = NetworkReachability.shared
    
    if reachability.isOnWiFi {
        // WiFi: Use larger batches, more frequent uploads
        updateRoverConfig(batchSize: 50, flushInterval: 30)
    } else if reachability.isOnCellular {
        // Cellular: Smaller batches, less frequent uploads
        updateRoverConfig(batchSize: 20, flushInterval: 60)
    } else {
        // Offline: Events will queue until connection returns
    }
}
```

## Memory Management

### 1. Monitor Event Queue Size

```swift
// In your app's memory monitoring
func checkRoverMemoryUsage() {
    let memoryBefore = getMemoryUsage()
    
    // Generate high event volume
    for i in 0..<1000 {
        rover.track(name: "Test Event \(i)")
    }
    
    let memoryAfter = getMemoryUsage()
    let growth = memoryAfter - memoryBefore
    
    // Alert if memory growth is excessive
    if growth > 5_000_000 {  // 5MB
        print("Warning: Rover memory usage high")
        rover.flush()  // Force upload to free memory
    }
}
```

### 2. Configure Bounded Queues

```swift
// For memory-constrained environments
let memoryConstrainedConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 10,        // Smaller batches
    flushInterval: 20,    // Frequent uploads
    maxQueueSize: 100     // Limit queue size
)
```

## Battery Optimization

### 1. Reduce Network Activity

```swift
// ✅ Battery-friendly configuration
let batteryOptimizedConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 50,        // Larger batches = fewer network calls
    flushInterval: 90,    // Less frequent uploads
    requestTimeout: 60    // Longer timeout = less retries
)

// ✅ Pause tracking during low battery
func batteryStateChanged() {
    let batteryLevel = UIDevice.current.batteryLevel
    
    if batteryLevel < 0.15 {  // Below 15%
        rover.setTrackingEnabled(false)
        print("Rover tracking paused - low battery")
    } else if batteryLevel > 0.25 {  // Above 25%
        rover.setTrackingEnabled(true)
        print("Rover tracking resumed")
    }
}
```

### 2. Background Processing

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
    // Request background time for final upload
    var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    
    backgroundTaskID = application.beginBackgroundTask {
        application.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }
    
    rover.flush()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        application.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }
}
```

## Threading and Concurrency

### 1. Thread-Safe Usage

```swift
// ✅ Rover is thread-safe - call from any queue
DispatchQueue.global(qos: .background).async {
    rover.track(name: "Background Task Completed", category: .functional)
}

DispatchQueue.main.async {
    rover.track(name: "UI Interaction", category: .tracking)
}

// ✅ Concurrent event tracking is safe
let dispatchGroup = DispatchGroup()

for i in 0..<100 {
    dispatchGroup.enter()
    DispatchQueue.global().async {
        rover.track(name: "Concurrent Event \(i)")
        dispatchGroup.leave()
    }
}
```

### 2. Avoid Main Thread Blocking

```swift
// ✅ Event tracking doesn't block main thread
@IBAction func buttonTapped(_ sender: UIButton) {
    // This is fast and non-blocking
    rover.track(name: "Button Tapped", category: .tracking)
    
    // Continue with UI updates immediately
    updateUI()
}

// ✅ Manual flush is also non-blocking
func uploadEvents() {
    rover.flush()  // Returns immediately, uploads in background
    
    // Continue with other work
    performOtherTasks()
}
```

## Performance Monitoring

### 1. Built-in Performance Logging

```swift
// Enable debug mode to see performance metrics
let config = RoverConfiguration(
    apiKey: "your-key",
    debugMode: true  // Shows timing and performance info
)
```

Debug output includes:
```
[Rover] Event tracked in 3ms: "Screen Viewed" (functional)
[Rover] Batch uploaded in 245ms (20 events, 1.2KB)
[Rover] Queue size: 5 events, estimated memory: 0.8KB
```

### 2. Custom Performance Tracking

```swift
class RoverPerformanceMonitor {
    private var trackingTimes: [TimeInterval] = []
    
    func trackEventWithTiming(name: String, category: EventCategory) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        rover.track(name: name, category: category)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        trackingTimes.append(duration)
        
        // Alert if tracking becomes slow
        if duration > 0.01 {  // 10ms
            print("Slow event tracking: \(name) took \(duration*1000)ms")
        }
    }
    
    func getAverageTrackingTime() -> TimeInterval {
        guard !trackingTimes.isEmpty else { return 0 }
        return trackingTimes.reduce(0, +) / Double(trackingTimes.count)
    }
}
```

### 3. Integration with App Performance Tools

```swift
// Xcode Instruments
import os.signpost

let roverLog = OSLog(subsystem: "com.yourapp.rover", category: "performance")

func trackWithInstrumentation(name: String) {
    os_signpost(.begin, log: roverLog, name: "Event Tracking", "Event: %@", name)
    
    rover.track(name: name)
    
    os_signpost(.end, log: roverLog, name: "Event Tracking")
}

// Firebase Performance Monitoring
func trackWithFirebasePerf(name: String) {
    let trace = Performance.startTrace(name: "rover_event_tracking")
    trace?.setValue(name, forAttribute: "event_name")
    
    rover.track(name: name)
    
    trace?.stop()
}
```

## Common Performance Pitfalls

### 1. Excessive Event Volume

```swift
// ❌ Don't do this: Too many events
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    rover.track(name: "Scroll Position Changed")  // Called hundreds of times
}

// ✅ Better: Throttled or significant events only
var lastScrollTrackTime: Date = Date()

func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let now = Date()
    if now.timeIntervalSince(lastScrollTrackTime) > 5.0 {  // Max once per 5 seconds
        rover.track(name: "User Scrolled", category: .tracking)
        lastScrollTrackTime = now
    }
}

// ✅ Even better: Track meaningful events
func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    rover.track(name: "Scroll Completed", category: .tracking)
}
```

### 2. Synchronous Operations

```swift
// ❌ Don't wait for uploads
func criticalUserAction() {
    rover.track(name: "Critical Action")
    rover.flush()
    
    // Don't block waiting for upload
    waitForUploadCompletion()  // Bad!
    
    continueCriticalWork()
}

// ✅ Fire and forget
func criticalUserAction() {
    rover.track(name: "Critical Action")
    rover.flush()  // Non-blocking
    
    // Continue immediately
    continueCriticalWork()
}
```

### 3. Memory Leaks in Properties

```swift
// ❌ Avoid strong references in event properties
class ViewController: UIViewController {
    func trackScreenView() {
        rover.track(name: "Screen Viewed", properties: [
            "view_controller": self  // Strong reference - potential leak!
        ])
    }
}

// ✅ Use identifiers instead
class ViewController: UIViewController {
    func trackScreenView() {
        rover.track(name: "Screen Viewed", properties: [
            "screen_name": String(describing: type(of: self)),
            "screen_id": String(format: "%p", self)  // Address as identifier
        ])
    }
}
```

## Performance Testing

### 1. Automated Performance Tests

```swift
class RoverPerformanceTests: XCTestCase {
    
    func testEventTrackingPerformance() {
        let rover = createTestRover()
        
        measure {
            for i in 0..<100 {
                rover.track(name: "Performance Test \(i)", category: .tracking)
            }
        }
    }
    
    func testBatchUploadPerformance() {
        let rover = createTestRover()
        
        // Fill the queue
        for i in 0..<50 {
            rover.track(name: "Batch Test \(i)")
        }
        
        measure {
            rover.flush()
        }
    }
    
    func testMemoryUsage() {
        let rover = createTestRover()
        let initialMemory = getMemoryUsage()
        
        // Generate events
        for i in 0..<1000 {
            rover.track(name: "Memory Test \(i)")
        }
        
        let finalMemory = getMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory
        
        XCTAssertLessThan(memoryGrowth, 2_000_000, "Memory growth should be under 2MB")
    }
}
```

### 2. Load Testing

```swift
func stressTestEventTracking() {
    let rover = createTestRover()
    let eventCount = 10_000
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    DispatchQueue.concurrentPerform(iterations: eventCount) { i in
        rover.track(name: "Stress Test \(i)", properties: [
            "iteration": i,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    let eventsPerSecond = Double(eventCount) / duration
    
    print("Processed \(eventsPerSecond) events per second")
    XCTAssertGreaterThan(eventsPerSecond, 1000, "Should handle at least 1000 events/second")
}
```

## See Also

- **[Performance Benchmarks](benchmarks.html)** - Detailed performance metrics and comparisons
- **[Event Batching Guide](event-batching.html)** - How batching works internally
- **[Configuration Guide](../getting-started/configuration.html)** - Performance-related configuration options
- **[Migration Guide](../migration/from-rover-4.html)** - Performance improvements in Rover 5

---

*These best practices are based on real-world usage patterns and performance testing. Apply them based on your specific app requirements and usage patterns.*