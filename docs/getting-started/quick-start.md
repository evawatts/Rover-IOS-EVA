# Quick Start Guide

Get up and running with Rover 5 in just a few minutes. This guide will walk you through the basic setup and your first event tracking implementation.

## Prerequisites

- Rover 5 SDK [installed](installation.html) in your project
- Your Rover API key (available in [Rover Settings](https://app.rover.io/settings))

## Step 1: Initialize the SDK

The simplest way to get started with Rover 5:

```swift
import UIKit
import Rover

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var rover: Rover?
    
    func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Rover 5 - Simple!
        rover = Rover(configuration: RoverConfiguration(
            apiKey: "your-api-key-here"
        ))
        
        return true
    }
}
```

### Configuration Options

For more control, you can specify additional options:

```swift
let configuration = RoverConfiguration(
    apiKey: "your-api-key-here",
    baseURL: "https://engage.rover.io",  // Default endpoint
    debugMode: true,                     // Enable debug logging
    batchSize: 20,                      // Events per batch
    flushInterval: 30                    // Seconds between uploads
)

rover = Rover(configuration: configuration)
```

## Step 2: Track Your First Event

Rover 5 makes event tracking incredibly simple:

### Basic Event Tracking

```swift
// Track functional events (app behavior)
rover?.track(name: "App Opened", category: .functional)
rover?.track(name: "Screen Viewed", category: .functional)

// Track engagement events (user interactions)
rover?.track(name: "Button Tapped", category: .tracking)
rover?.track(name: "Content Shared", category: .tracking)
```

### Events with Properties

Add custom properties to provide context:

```swift
rover?.track(
    name: "Screen Viewed",
    category: .functional,
    properties: [
        "screen_name": "home",
        "user_type": "premium"
    ]
)

rover?.track(
    name: "Purchase",
    category: .tracking,
    properties: [
        "product_id": "item_123",
        "price": 29.99,
        "currency": "USD"
    ]
)
```

### Auto-Classification

Don't want to specify categories? Rover 5 can auto-classify events:

```swift
// These will be automatically categorized
rover?.track(name: "App Opened")      // → .functional
rover?.track(name: "Screen Viewed")   // → .functional
rover?.track(name: "Button Tapped")   // → .tracking
rover?.track(name: "Link Clicked")    // → .tracking
```

## Step 3: User Identification

Associate events with specific users:

```swift
// Set user token (JWT from your auth system)
rover?.setUserToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")

// Set user attributes
rover?.setUserAttributes([
    "user_id": "12345",
    "email": "user@example.com",
    "plan": "premium",
    "signup_date": "2024-01-15"
])
```

### Clear User Data

When users log out:

```swift
rover?.setUserToken(nil)  // Clear the user token
```

## Step 4: Privacy Controls

Rover 5 includes built-in privacy controls:

```swift
// Enable/disable tracking (GDPR compliance)
rover?.setTrackingEnabled(true)   // Enable analytics
rover?.setTrackingEnabled(false)  // Disable analytics

// Check current tracking status
let isEnabled = rover?.isTrackingEnabled ?? false
```

## Complete Example

Here's a complete working example in a SwiftUI app:

```swift
import SwiftUI
import Rover

@main
struct MyApp: App {
    @State private var rover: Rover?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupRover()
                }
        }
    }
    
    private func setupRover() {
        rover = Rover(configuration: RoverConfiguration(
            apiKey: "your-api-key-here",
            debugMode: true
        ))
        
        // Track app launch
        rover?.track(name: "App Opened", category: .functional)
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, Rover 5!")
            
            Button("Track Button Tap") {
                // Access rover from environment or pass it down
                // rover?.track(name: "Button Tapped", category: .tracking)
            }
        }
    }
}
```

## What Happens Next?

Once you start tracking events:

1. **Events are Batched** - Rover automatically batches events for efficiency
2. **Automatic Upload** - Events are uploaded to `engage.rover.io` periodically
3. **Offline Support** - Events are saved locally and uploaded when online
4. **Error Handling** - Failed uploads are retried automatically

## Testing Your Integration

### Debug Mode

Enable debug mode to see what's happening:

```swift
let configuration = RoverConfiguration(
    apiKey: "your-api-key-here",
    debugMode: true  // This will log event activity
)
```

### Manual Flush

Force immediate event upload for testing:

```swift
rover?.flush()  // Upload all pending events now
```

## Common Patterns

### Screen Tracking

Track screen views consistently:

```swift
extension UIViewController {
    func trackScreenView() {
        let screenName = String(describing: type(of: self))
        rover?.track(
            name: "Screen Viewed",
            category: .functional,
            properties: ["screen": screenName]
        )
    }
}

// In your view controllers:
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    trackScreenView()
}
```

### Event Categories

Use consistent event categorization:

- **Functional Events** (.functional): App behavior, navigation, lifecycle
- **Tracking Events** (.tracking): User interactions, engagement, conversions

## Next Steps

Now that you have basic tracking working:

1. **[Configuration Guide](configuration.html)** - Learn about all configuration options
2. **[API Reference](../api-reference/rover.html)** - Explore the complete API
3. **[Migration Guide](../migration/from-rover-4.html)** - Upgrading from Rover 4
4. **[Performance Guide](../performance/best-practices.html)** - Optimization tips

## Troubleshooting

### Events Not Appearing?

1. Check your API key is correct
2. Verify network connectivity
3. Enable debug mode to see logs
4. Try manual flush: `rover?.flush()`

### Build Issues?

1. Ensure iOS 13.0+ deployment target
2. Clean build folder and rebuild
3. Check [installation guide](installation.html) steps

## Support

Need help getting started?

- **GitHub Issues**: [Report problems](https://github.com/evawatts/Rover-IOS-EVA/issues)
- **Email Support**: [Contact our team](mailto:support@rover.io)
- **Documentation**: [Full API Reference](../api-reference/rover.html)

---

*Ready to learn more? Check out the [Configuration Guide](configuration.html) or dive into the [API Reference](../api-reference/rover.html).*