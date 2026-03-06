# Rover Class Reference

The `Rover` class is the main interface for the Rover 5 iOS SDK. It provides a simple, intuitive API for event tracking, user management, and privacy controls.

## Overview

```swift
import Rover

let rover = Rover(configuration: RoverConfiguration(apiKey: "your-api-key"))
```

The Rover class encapsulates all SDK functionality and provides a clean, modern API inspired by leading analytics SDKs.

## Initialization

### `init(configuration: RoverConfiguration)`

Creates a new Rover instance with the specified configuration.

```swift
let rover = Rover(configuration: RoverConfiguration(
    apiKey: "your-api-key-here",
    baseURL: "https://engage.rover.io",  // Optional
    debugMode: false,                    // Optional
    batchSize: 20,                      // Optional
    flushInterval: 30                    // Optional
))
```

**Parameters:**
- `configuration: RoverConfiguration` - SDK configuration options

**Returns:** A configured Rover instance ready for use.

## Event Tracking

### `track(name: String, category: EventCategory)`

Track an event with explicit category classification.

```swift
rover.track(name: "Screen Viewed", category: .functional)
rover.track(name: "Button Tapped", category: .tracking)
```

**Parameters:**
- `name: String` - Event name (required)
- `category: EventCategory` - Event category (`.functional` or `.tracking`)

---

### `track(name: String, category: EventCategory, properties: [String: Any])`

Track an event with additional properties.

```swift
rover.track(
    name: "Purchase",
    category: .tracking,
    properties: [
        "product_id": "item_123",
        "price": 29.99,
        "currency": "USD"
    ]
)
```

**Parameters:**
- `name: String` - Event name (required)
- `category: EventCategory` - Event category (`.functional` or `.tracking`)
- `properties: [String: Any]` - Additional event properties (optional)

---

### `track(name: String)`

Track an event with automatic category classification.

```swift
rover.track(name: "App Opened")      // → .functional
rover.track(name: "Button Tapped")   // → .tracking
```

**Parameters:**
- `name: String` - Event name (required)

**Note:** Uses built-in `EventClassifier` to determine appropriate category based on event name patterns.

---

### `track(name: String, properties: [String: Any])`

Track an event with properties and automatic category classification.

```swift
rover.track(
    name: "Screen Viewed",
    properties: ["screen": "home"]
)
```

**Parameters:**
- `name: String` - Event name (required)
- `properties: [String: Any]` - Additional event properties (optional)

## User Management

### `setUserToken(_ token: String?)`

Set or clear the user authentication token.

```swift
// Set user token
rover.setUserToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")

// Clear user token (logout)
rover.setUserToken(nil)
```

**Parameters:**
- `token: String?` - JWT token from your authentication system, or `nil` to clear

---

### `setUserAttributes(_ attributes: [String: Any])`

Set additional user attributes for personalization and segmentation.

```swift
rover.setUserAttributes([
    "user_id": "12345",
    "email": "user@example.com",
    "plan": "premium",
    "signup_date": "2024-01-15",
    "preferences": ["notifications": true]
])
```

**Parameters:**
- `attributes: [String: Any]` - Dictionary of user attributes

**Supported Value Types:**
- `String` - Text values
- `Int`, `Double`, `Float` - Numeric values
- `Bool` - Boolean values
- `Date` - Date values (automatically formatted)
- `Array`, `Dictionary` - Nested structures (JSON serializable)

## Privacy Controls

### `setTrackingEnabled(_ enabled: Bool)`

Enable or disable event tracking for privacy compliance.

```swift
rover.setTrackingEnabled(true)   // Enable tracking
rover.setTrackingEnabled(false)  // Disable tracking (GDPR compliance)
```

**Parameters:**
- `enabled: Bool` - Whether tracking should be enabled

**Behavior:**
- When disabled, events are not collected or sent
- Existing queued events are preserved
- Re-enabling resumes normal operation

---

### `isTrackingEnabled: Bool`

Check current tracking status.

```swift
let trackingStatus = rover.isTrackingEnabled
if trackingStatus {
    print("Tracking is enabled")
} else {
    print("Tracking is disabled")
}
```

**Returns:** `Bool` - Current tracking enabled/disabled state

## Event Management

### `flush()`

Immediately upload all pending events to the server.

```swift
rover.flush()  // Force immediate upload
```

**Use Cases:**
- Before app background/termination
- Testing event delivery
- Critical events that need immediate delivery

**Note:** Events are normally uploaded automatically based on `flushInterval` configuration.

---

### `clearEvents()`

Clear all pending events from local storage.

```swift
rover.clearEvents()  // Remove all queued events
```

**Use Cases:**
- Privacy compliance (user requests data deletion)
- Testing scenarios
- Error recovery

**Warning:** This permanently deletes events that haven't been uploaded.

## Event Categories

The SDK supports two event categories:

### `.functional`
Events related to app functionality and user navigation:
- App lifecycle events (launch, background, terminate)
- Screen views and navigation
- Feature usage
- System events

**Examples:**
```swift
rover.track(name: "App Opened", category: .functional)
rover.track(name: "Screen Viewed", category: .functional)
rover.track(name: "Feature Used", category: .functional)
```

### `.tracking`
Events related to user engagement and interactions:
- Button taps and clicks
- Content interactions
- User-generated actions
- Conversion events

**Examples:**
```swift
rover.track(name: "Button Tapped", category: .tracking)
rover.track(name: "Content Shared", category: .tracking)
rover.track(name: "Purchase", category: .tracking)
```

## Auto-Classification

When using `track(name:)` without explicit category, the SDK automatically classifies events:

### Functional Event Patterns
- `*opened*`, `*started*`, `*launched*`
- `*viewed*`, `*loaded*`, `*displayed*`
- `*navigation*`, `*screen*`, `*page*`
- `*session*`, `*app*`, `*lifecycle*`

### Tracking Event Patterns
- `*tapped*`, `*clicked*`, `*pressed*`
- `*shared*`, `*liked*`, `*commented*`
- `*purchased*`, `*converted*`, `*completed*`
- `*interaction*`, `*engagement*`, `*action*`

### Example Auto-Classification

```swift
// These will be automatically categorized:
rover.track(name: "App Opened")           // → .functional
rover.track(name: "Home Screen Viewed")   // → .functional
rover.track(name: "Menu Button Tapped")   // → .tracking
rover.track(name: "Article Shared")       // → .tracking
rover.track(name: "Video Played")         // → .tracking
```

## Error Handling

The Rover SDK handles errors gracefully:

### Network Errors
- Automatic retry with exponential backoff
- Events preserved locally during outages
- Resumption when connectivity returns

### Configuration Errors
- Invalid API keys logged in debug mode
- Graceful degradation (events queued, not sent)
- Clear error messages for troubleshooting

### Data Validation
- Invalid event properties filtered out
- Non-serializable data types converted or ignored
- Event names sanitized for API compatibility

## Thread Safety

The Rover class is **thread-safe** and can be called from any queue:

```swift
// Safe to call from background queues
DispatchQueue.global(qos: .background).async {
    rover.track(name: "Background Task Completed", category: .functional)
}

// Safe to call from main queue
DispatchQueue.main.async {
    rover.track(name: "UI Button Tapped", category: .tracking)
}
```

## Performance Considerations

### Event Batching
- Events are automatically batched for efficient network usage
- Default batch size: 20 events
- Configurable via `RoverConfiguration.batchSize`

### Memory Management
- Events are persisted to disk to handle app termination
- Memory usage is bounded by batch size
- Automatic cleanup of old events

### Network Efficiency
- REST API with JSON payloads
- Gzip compression for large batches
- Intelligent retry logic

## Example Usage

### Complete Integration Example

```swift
import UIKit
import Rover

class AppDelegate: UIResponder, UIApplicationDelegate {
    var rover: Rover!
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Rover
        rover = Rover(configuration: RoverConfiguration(
            apiKey: "your-api-key",
            debugMode: true
        ))
        
        // Track app launch
        rover.track(name: "App Opened", category: .functional)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        rover.track(name: "App Became Active", category: .functional)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        rover.track(name: "App Entered Background", category: .functional)
        rover.flush()  // Ensure events are sent
    }
}

class ViewController: UIViewController {
    var rover: Rover {
        return (UIApplication.shared.delegate as! AppDelegate).rover
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set user information
        rover.setUserAttributes([
            "user_type": "premium",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Track screen view
        rover.track(
            name: "Screen Viewed",
            category: .functional,
            properties: [
                "screen": String(describing: type(of: self)),
                "animation": animated
            ]
        )
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        rover.track(
            name: "Action Button Tapped",
            category: .tracking,
            properties: [
                "button_title": sender.titleLabel?.text ?? "",
                "screen": String(describing: type(of: self))
            ]
        )
    }
}
```

## See Also

- **[RoverConfiguration](configuration.html)** - Configuration options and defaults
- **[Event Tracking Guide](event-tracking.html)** - Detailed event tracking patterns
- **[User Management](user-management.html)** - User identification and attributes
- **[Migration Guide](../migration/from-rover-4.html)** - Upgrading from Rover 4

---

*For more examples and best practices, see the [Quick Start Guide](../getting-started/quick-start.html).*