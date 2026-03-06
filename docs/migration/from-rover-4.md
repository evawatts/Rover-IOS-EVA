# Migration from Rover 4 to Rover 5

This guide will help you migrate from Rover 4 to Rover 5. The new SDK provides a dramatically simplified API while maintaining all core functionality.

## Before You Begin

### What's Changed in Rover 5

- **🚀 Simplified API** - No more complex assemblers or dependency injection
- **📡 Single Endpoint** - All events go to `engage.rover.io`
- **⚡️ Better Performance** - Streamlined event processing and REST API
- **🔧 Easier Setup** - One-line initialization vs complex assembler setup

### Compatibility

- **Minimum iOS Version**: 13.0+ (up from 12.0)
- **Xcode Version**: 12.0+ (up from 11.0)
- **Swift Version**: 5.3+ (up from 5.0)

## Step 1: Update Dependencies

### Remove Rover 4

First, remove the old Rover 4 dependency:

1. In Xcode, go to your project settings
2. Under **Package Dependencies**, remove the old Rover package
3. Clean your build folder

### Add Rover 5

Add the new Rover 5 SDK:

```
https://github.com/evawatts/Rover-IOS-EVA
```

See the [Installation Guide](../getting-started/installation.html) for detailed steps.

## Step 2: Update Initialization

The most significant change is in SDK initialization.

### Rover 4 Initialization (Old)

```swift
import RoverFoundation
import RoverData
import RoverUI
import RoverExperiences
import RoverNotifications
import RoverDebug

func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Complex assembler setup
    let assemblers: [Assembler] = [
        FoundationAssembler(),
        DataAssembler(accountToken: "your-account-token"),
        UIAssembler(),
        ExperiencesAssembler(),
        NotificationsAssembler(),
        DebugAssembler()
    ]
    
    Rover.initialize(assemblers: assemblers)
    return true
}
```

### Rover 5 Initialization (New)

```swift
import Rover

func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Simple initialization
    let rover = Rover(configuration: RoverConfiguration(
        apiKey: "your-api-key-here"  // Note: API key, not account token
    ))
    
    return true
}
```

### Key Differences

| Rover 4 | Rover 5 |
|---------|---------|
| Multiple imports | Single `import Rover` |
| Complex assemblers | Simple configuration |
| Account token | API key |
| Global shared instance | Instance-based |

## Step 3: Update Event Tracking

Event tracking has been simplified while maintaining full functionality.

### Rover 4 Event Tracking (Old)

```swift
// Complex event creation
let event = Event(
    name: "Screen Viewed",
    context: [
        "screen": "home",
        "user_id": "12345"
    ],
    category: .tracking
)

// Add to event queue
Rover.shared.eventQueue.addEvent(event)

// Or using convenience method
Rover.shared.eventQueue.addEvent(
    Event(name: "Button Tapped", context: [:], category: .tracking)
)
```

### Rover 5 Event Tracking (New)

```swift
// Simple track methods
rover.track(name: "Screen Viewed", category: .functional)
rover.track(name: "Button Tapped", category: .tracking)

// With properties
rover.track(
    name: "Screen Viewed", 
    category: .functional,
    properties: [
        "screen": "home",
        "user_id": "12345"
    ]
)

// Auto-classification (optional)
rover.track(name: "Screen Viewed")  // Automatically categorized as .functional
rover.track(name: "Button Tapped")  // Automatically categorized as .tracking
```

### Event Category Mapping

Event categories remain the same:

| Category | Description | Example Events |
|----------|-------------|----------------|
| `.functional` | App behavior and navigation | App Opened, Screen Viewed |
| `.tracking` | User interactions and engagement | Button Tapped, Content Shared |

## Step 4: Update User Management

User identification has been streamlined.

### Rover 4 User Management (Old)

```swift
// Set user info via event context or attributes
Rover.shared.userInfoManager.update(userInfo: [
    "user_id": "12345",
    "email": "user@example.com"
])
```

### Rover 5 User Management (New)

```swift
// Set user token (JWT from your auth system)
rover.setUserToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")

// Set user attributes
rover.setUserAttributes([
    "user_id": "12345",
    "email": "user@example.com",
    "plan": "premium"
])

// Clear user data on logout
rover.setUserToken(nil)
```

## Step 5: Update Privacy Controls

Privacy management is now built into the main API.

### Rover 4 Privacy (Old)

```swift
// Access privacy manager
Rover.shared.privacyService.setTrackingEnabled(false)
```

### Rover 5 Privacy (New)

```swift
// Direct privacy controls
rover.setTrackingEnabled(false)  // Disable tracking
rover.setTrackingEnabled(true)   // Enable tracking

// Check status
let isEnabled = rover.isTrackingEnabled
```

## Step 6: Handle Breaking Changes

### Removed Features

Some Rover 4 features are not available in Rover 5:

- **Complex Assemblers** - Replaced with simple configuration
- **GraphQL API** - Replaced with REST API
- **Modular Imports** - Single unified framework
- **Global Shared Instance** - Use instance-based approach

### API Changes

| Rover 4 | Rover 5 | Status |
|---------|---------|---------|
| `Rover.shared` | `rover` instance | Changed |
| `eventQueue.addEvent()` | `track()` | Simplified |
| `Event(name:context:category:)` | `track(name:category:properties:)` | Simplified |
| Account Token | API Key | Changed |
| Multiple modules | Single framework | Unified |

## Step 7: Update Configuration

### Rover 4 Configuration (Old)

```swift
// Complex assembler configuration
DataAssembler(
    accountToken: "token",
    apiEndpoint: "https://api.rover.io/graphql"
)

DebugAssembler(logLevel: .debug)
```

### Rover 5 Configuration (New)

```swift
let configuration = RoverConfiguration(
    apiKey: "your-api-key",
    baseURL: "https://engage.rover.io",  // Default
    debugMode: true,
    batchSize: 20,
    flushInterval: 30
)
```

## Migration Examples

### Complete Before/After Example

#### Rover 4 Implementation

```swift
// AppDelegate.swift
import UIKit
import RoverFoundation
import RoverData
import RoverUI
import RoverDebug

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Complex setup
        let assemblers: [Assembler] = [
            FoundationAssembler(),
            DataAssembler(accountToken: "rover-token-123"),
            UIAssembler(),
            DebugAssembler()
        ]
        
        Rover.initialize(assemblers: assemblers)
        
        // Track app launch
        Rover.shared.eventQueue.addEvent(
            Event(name: "App Opened", context: [:], category: .functional)
        )
        
        return true
    }
}

// ViewController.swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Track screen view
        Rover.shared.eventQueue.addEvent(
            Event(
                name: "Screen Viewed",
                context: ["screen": "home"],
                category: .functional
            )
        )
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        // Track interaction
        Rover.shared.eventQueue.addEvent(
            Event(name: "Button Tapped", context: [:], category: .tracking)
        )
    }
}
```

#### Rover 5 Implementation

```swift
// AppDelegate.swift
import UIKit
import Rover

class AppDelegate: UIResponder, UIApplicationDelegate {
    var rover: Rover?
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Simple setup
        rover = Rover(configuration: RoverConfiguration(
            apiKey: "rover-api-key-456",
            debugMode: true
        ))
        
        // Track app launch
        rover?.track(name: "App Opened", category: .functional)
        
        return true
    }
}

// ViewController.swift
class ViewController: UIViewController {
    var rover: Rover? // Get from AppDelegate or dependency injection
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Track screen view
        rover?.track(
            name: "Screen Viewed", 
            category: .functional,
            properties: ["screen": "home"]
        )
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        // Track interaction
        rover?.track(name: "Button Tapped", category: .tracking)
    }
}
```

## Migration Checklist

### Pre-Migration

- [ ] Review current Rover 4 implementation
- [ ] Identify all event tracking calls
- [ ] Note custom configuration settings
- [ ] Backup your current implementation

### During Migration

- [ ] Remove Rover 4 package dependency
- [ ] Add Rover 5 package dependency
- [ ] Update imports (`import Rover`)
- [ ] Replace assembler initialization with simple configuration
- [ ] Convert `Event` creation to `track()` calls
- [ ] Update user management calls
- [ ] Update privacy control calls
- [ ] Test event tracking

### Post-Migration

- [ ] Verify events are being sent to `engage.rover.io`
- [ ] Test user identification
- [ ] Test privacy controls
- [ ] Validate performance improvements
- [ ] Update team documentation

## Troubleshooting

### Common Issues

**Build Errors After Migration**
- Clean build folder
- Reset package caches
- Verify iOS 13.0+ deployment target

**Events Not Sending**
- Check API key (not account token)
- Verify network connectivity
- Enable debug mode
- Check engage.rover.io endpoint

**Missing User Data**
- Update to `setUserToken()` method
- Use `setUserAttributes()` for additional data
- Verify JWT token format

### Getting Help

- **Migration Issues**: [Open GitHub Issue](https://github.com/evawatts/Rover-IOS-EVA/issues)
- **API Questions**: [API Reference](../api-reference/rover.html)
- **Email Support**: [Contact Team](mailto:support@rover.io)

## Performance Benefits

After migration, you should see:

- **50% Faster Initialization** - No complex assembler setup
- **30% Reduced Memory Usage** - Unified framework architecture
- **Better Network Efficiency** - REST API vs GraphQL
- **Improved Event Processing** - Streamlined batching

See [Performance Benchmarks](../performance/benchmarks.html) for detailed metrics.

---

*Migration complete? Learn about [Performance Optimization](../performance/best-practices.html) or explore the [API Reference](../api-reference/rover.html).*