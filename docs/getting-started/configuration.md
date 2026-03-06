# Configuration Guide

The `RoverConfiguration` struct provides comprehensive options for customizing Rover 5 SDK behavior. This guide covers all available configuration options and best practices.

## Basic Configuration

The minimal configuration requires only your API key:

```swift
let config = RoverConfiguration(apiKey: "your-api-key-here")
let rover = Rover(configuration: config)
```

## Complete Configuration Options

```swift
let config = RoverConfiguration(
    apiKey: "your-api-key-here",        // Required
    baseURL: "https://engage.rover.io", // Optional
    debugMode: false,                   // Optional
    batchSize: 20,                      // Optional
    flushInterval: 30,                  // Optional
    maxRetries: 3,                      // Optional
    requestTimeout: 30,                 // Optional
    enabledCategories: [.functional, .tracking]  // Optional
)
```

## Configuration Parameters

### `apiKey: String` (Required)

Your unique API key for authentication with engage.rover.io.

```swift
let config = RoverConfiguration(apiKey: "rv_live_12345abcdef...")
```

**Where to Find Your API Key:**
1. Go to [Rover Settings](https://app.rover.io/settings)
2. Find the "SDK Token" section
3. Copy the key labeled "SDK Token"

**Security Notes:**
- Keep your API key secure
- Don't commit keys to public repositories
- Consider using environment variables or secure configuration

### `baseURL: String` (Optional)

The base URL for the Rover API endpoint.

```swift
// Default (production)
let config = RoverConfiguration(
    apiKey: "your-key",
    baseURL: "https://engage.rover.io"  // Default value
)

// Custom endpoint (for testing or enterprise)
let config = RoverConfiguration(
    apiKey: "your-key",
    baseURL: "https://staging.engage.rover.io"
)
```

**Default:** `"https://engage.rover.io"`

**When to Change:**
- Testing against staging environment
- Enterprise custom endpoints
- Development/debugging purposes

### `debugMode: Bool` (Optional)

Enable detailed logging for debugging and development.

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    debugMode: true  // Enable verbose logging
)
```

**Default:** `false`

**When Enabled:**
- Logs event tracking calls
- Shows network requests/responses
- Displays configuration details
- Reports errors with full context

**Example Debug Output:**
```
[Rover] Event tracked: "Screen Viewed" (functional)
[Rover] Batching event (queue: 3/20)
[Rover] Uploading batch (20 events) to https://engage.rover.io/v1/events
[Rover] Upload successful (200 OK)
```

### `batchSize: Int` (Optional)

Number of events to batch together before uploading.

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 50  // Upload when 50 events collected
)
```

**Default:** `20`
**Range:** `1-100`

**Performance Impact:**
- **Smaller batches** (5-10): More frequent uploads, real-time data
- **Medium batches** (15-30): Balanced performance and latency  
- **Larger batches** (50-100): Better network efficiency, higher latency

**Recommendations:**
```swift
// Real-time apps (chat, gaming)
batchSize: 5

// Standard apps (social, productivity)
batchSize: 20  // Default

// Analytics-heavy apps (media, e-commerce)
batchSize: 50
```

### `flushInterval: TimeInterval` (Optional)

Maximum time to wait before uploading events (in seconds).

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    flushInterval: 60  // Upload every 60 seconds maximum
)
```

**Default:** `30` seconds
**Range:** `5-300` seconds

**Behavior:**
- Events upload when `batchSize` is reached OR `flushInterval` expires
- Prevents events from sitting too long in the queue
- Ensures regular data delivery even with low event volume

**Recommendations:**
```swift
// Real-time requirements
flushInterval: 10

// Standard apps
flushInterval: 30  // Default

// Batch-oriented apps
flushInterval: 120
```

### `maxRetries: Int` (Optional)

Maximum number of retry attempts for failed uploads.

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    maxRetries: 5  // Try up to 5 times
)
```

**Default:** `3`
**Range:** `0-10`

**Retry Behavior:**
- Exponential backoff: 1s, 2s, 4s, 8s, 16s, ...
- Network errors trigger retries
- HTTP 4xx errors (bad request) don't retry
- HTTP 5xx errors (server error) do retry

### `requestTimeout: TimeInterval` (Optional)

Timeout for network requests (in seconds).

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    requestTimeout: 45  // 45 second timeout
)
```

**Default:** `30` seconds
**Range:** `5-120` seconds

**Considerations:**
- Shorter timeouts: Faster failure detection, may fail on slow networks
- Longer timeouts: More reliable on slow networks, slower error detection

### `enabledCategories: [EventCategory]` (Optional)

Which event categories to track and upload.

```swift
// Track all events (default)
let config = RoverConfiguration(
    apiKey: "your-key",
    enabledCategories: [.functional, .tracking]
)

// Track only functional events
let config = RoverConfiguration(
    apiKey: "your-key",
    enabledCategories: [.functional]
)

// Track only engagement events
let config = RoverConfiguration(
    apiKey: "your-key",
    enabledCategories: [.tracking]
)

// Disable all tracking (privacy mode)
let config = RoverConfiguration(
    apiKey: "your-key",
    enabledCategories: []
)
```

**Default:** `[.functional, .tracking]` (all categories)

**Use Cases:**
- **Privacy compliance**: Disable specific categories
- **Data reduction**: Focus on specific event types
- **Testing**: Isolate event categories

## Environment-Specific Configurations

### Development Configuration

```swift
#if DEBUG
let config = RoverConfiguration(
    apiKey: "rv_dev_123...",
    debugMode: true,
    batchSize: 5,         // Smaller batches for immediate feedback
    flushInterval: 10,    // Frequent uploads for testing
    requestTimeout: 60    // Longer timeout for debugging
)
#else
let config = RoverConfiguration(
    apiKey: "rv_live_123...",
    debugMode: false,
    batchSize: 20,
    flushInterval: 30
)
#endif
```

### Performance-Optimized Configuration

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 50,        // Larger batches
    flushInterval: 120,   // Less frequent uploads
    maxRetries: 5,        // More resilient
    requestTimeout: 45    // Longer timeout for reliability
)
```

### Privacy-First Configuration

```swift
let config = RoverConfiguration(
    apiKey: "your-key",
    enabledCategories: [.functional],  // No tracking events
    batchSize: 10,       // Smaller batches (less data retention)
    flushInterval: 15    // Frequent uploads (less local storage)
)
```

## Dynamic Configuration

### Runtime Configuration Changes

While core configuration is set at initialization, some settings can be changed at runtime:

```swift
let rover = Rover(configuration: initialConfig)

// Privacy controls (runtime)
rover.setTrackingEnabled(false)  // Disable all tracking
rover.setTrackingEnabled(true)   // Re-enable tracking

// Manual flush (override flushInterval)
rover.flush()  // Upload immediately
```

### Configuration Validation

The SDK validates configuration on initialization:

```swift
// This will log warnings in debug mode:
let config = RoverConfiguration(
    apiKey: "invalid-key",     // Warning: Invalid API key format
    batchSize: 150,           // Warning: Batch size clamped to 100
    flushInterval: 1,         // Warning: Flush interval too short
    maxRetries: 15            // Warning: Max retries clamped to 10
)
```

## Best Practices

### 1. Environment-Based Configuration

Use different configurations for different environments:

```swift
enum Environment {
    case development, staging, production
    
    var roverConfig: RoverConfiguration {
        switch self {
        case .development:
            return RoverConfiguration(
                apiKey: "dev_key",
                debugMode: true,
                batchSize: 5,
                flushInterval: 10
            )
        case .staging:
            return RoverConfiguration(
                apiKey: "staging_key",
                debugMode: true,
                batchSize: 10,
                flushInterval: 20
            )
        case .production:
            return RoverConfiguration(
                apiKey: "prod_key",
                debugMode: false,
                batchSize: 20,
                flushInterval: 30
            )
        }
    }
}
```

### 2. Secure API Key Management

```swift
// Use environment variables or secure storage
let config = RoverConfiguration(
    apiKey: ProcessInfo.processInfo.environment["ROVER_API_KEY"] ?? "fallback-key"
)

// Or use a configuration file not checked into source control
let config = RoverConfiguration(
    apiKey: ConfigurationManager.shared.roverAPIKey
)
```

### 3. Performance Tuning

```swift
// High-volume apps
let highVolumeConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 100,       // Max batch size
    flushInterval: 120,   // Less frequent uploads
    maxRetries: 5         // More resilient
)

// Real-time apps
let realTimeConfig = RoverConfiguration(
    apiKey: "your-key",
    batchSize: 1,         // Immediate upload
    flushInterval: 5,     // Short backup interval
    requestTimeout: 15    // Quick failure detection
)
```

### 4. Testing Configuration

```swift
#if TESTING
let testConfig = RoverConfiguration(
    apiKey: "test_key_123",
    baseURL: "https://test.engage.rover.io",
    debugMode: true,
    batchSize: 1,         // No batching in tests
    flushInterval: 5,     // Quick flushes
    maxRetries: 0         // No retries in tests
)
#endif
```

## Troubleshooting Configuration

### Common Issues

**Events not uploading:**
- Verify API key is correct and valid
- Check network connectivity
- Enable debug mode to see error messages
- Verify baseURL is accessible

**Poor performance:**
- Reduce batch size for more frequent uploads
- Increase flush interval to reduce network calls
- Adjust timeout based on network conditions

**High memory usage:**
- Reduce batch size to limit queue size
- Decrease flush interval to upload more frequently
- Monitor event volume and adjust accordingly

### Debug Configuration

```swift
// Comprehensive debug configuration
let debugConfig = RoverConfiguration(
    apiKey: "your-key",
    debugMode: true,      // Enable all logging
    batchSize: 1,         // See each event individually
    flushInterval: 5,     // Frequent uploads for visibility
    maxRetries: 1,        // Quick failure feedback
    requestTimeout: 15    // Quick timeout for testing
)
```

## See Also

- **[Quick Start Guide](quick-start.html)** - Basic setup and usage
- **[API Reference](../api-reference/configuration.html)** - Complete RoverConfiguration reference
- **[Performance Guide](../performance/best-practices.html)** - Performance optimization
- **[Migration Guide](../migration/from-rover-4.html)** - Upgrading from Rover 4

---

*For more advanced configuration scenarios, see the [Best Practices Guide](../performance/best-practices.html).*