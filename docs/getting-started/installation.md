---
layout: page
title: Installation Guide
---

The Rover 5 iOS SDK is designed for easy integration with modern iOS development workflows. Follow this step-by-step guide to add Rover 5 to your project.

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## Installation Methods

### Swift Package Manager (Recommended)

Rover 5 SDK is distributed via Swift Package Manager, Apple's official dependency manager.

#### Step 1: Add Package Dependency

1. Open your project in Xcode
2. Navigate to **File → Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/evawatts/Rover-IOS-EVA
   ```
4. Press **Return** to search

![Add Package Dependencies](../images/swiftpm-add-package.png)

#### Step 2: Select Version

1. Choose **"Up to Next Major Version"** (recommended)
2. Leave the version set to the latest available
3. Click **Add Package**

#### Step 3: Select Target

1. Select your app target from the dropdown
2. Choose the **"Rover"** product to add to your target
3. Click **Add Package**

![Select Package Products](../images/swiftpm-select-products.png)

### Manual Installation

If you prefer manual installation or need to customize the SDK:

1. Clone the repository:
   ```bash
   git clone https://github.com/evawatts/Rover-IOS-EVA.git
   ```

2. Drag the `Rover-IOS-EVA.xcodeproj` file into your Xcode project

3. Add the **Rover** framework to your target's dependencies

## Verify Installation

After installation, verify the SDK is properly integrated:

```swift
import Rover

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Test SDK integration
        print("Rover SDK installed successfully")
        return true
    }
}
```

## What's Included

The Rover 5 SDK includes:

- **Core Rover Framework** - Main SDK functionality
- **Event Tracking** - Analytics and engagement events
- **User Management** - User identification and attributes
- **REST Client** - Communicate with engage.rover.io
- **Privacy Controls** - GDPR and privacy compliance

## Package Structure

```
Rover/
├── Rover.swift              # Main SDK class
├── RoverConfiguration.swift # Configuration options
├── EngageEventsClient.swift # REST API client
├── SimpleEventQueue.swift   # Event batching and processing
└── Supporting Files/        # Internal implementation
```

## Next Steps

Once installation is complete:

1. **[Quick Start Guide](quick-start.html)** - Initialize the SDK and track your first event
2. **[Configuration Options](configuration.html)** - Customize SDK behavior
3. **[Migration Guide](../migration/from-rover-4.html)** - Upgrading from Rover 4

## Common Issues

### Build Errors

If you encounter build errors after installation:

1. **Clean Build Folder** - Product → Clean Build Folder
2. **Reset Package Caches** - File → Packages → Reset Package Caches
3. **Update to Latest Xcode** - Ensure you're using Xcode 15.0+

### Import Issues

If `import Rover` fails:

1. Verify the package is added to your target
2. Check your deployment target is iOS 17.0+
3. Ensure you've selected the "Rover" product during installation

### Network Issues

If package download fails:

1. Check your internet connection
2. Verify repository URL: `https://github.com/evawatts/Rover-IOS-EVA`
3. Try adding the package again

## Support

Need help with installation?

- **GitHub Issues**: [Report installation problems](https://github.com/evawatts/Rover-IOS-EVA/issues)
- **Email Support**: [Contact our team](mailto:support@rover.io)
- **Documentation**: Continue with [Quick Start](quick-start.html)

---

*Ready to initialize the SDK? Continue to the [Quick Start Guide](quick-start.html).*