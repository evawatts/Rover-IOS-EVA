# Rover 5 iOS SDK Documentation

Welcome to the official documentation for the **Rover 5 iOS SDK** - a dramatically simplified, modern SDK for creating mobile experiences and marketing campaign automation.

## What's New in Rover 5

Rover 5 represents a complete rewrite of the iOS SDK with a focus on simplicity, performance, and developer experience. The new SDK provides:

- **🚀 Dramatically Simplified API** - Segment-inspired interface with simple initialization
- **📡 Single Endpoint Architecture** - All events go to `engage.rover.io` via REST API
- **🔧 No Complex Setup** - No more assemblers or dependency injection
- **⚡️ Improved Performance** - Streamlined event processing and batching
- **🔒 Privacy-First** - Enhanced privacy controls and GDPR compliance

## Quick Start

Get up and running with Rover 5 in minutes:

```swift
import Rover

// Simple initialization
let rover = Rover(configuration: RoverConfiguration(
    apiKey: "your-api-key"
))

// Track events with ease
rover.track(name: "App Opened", category: .functional)
rover.track(name: "Screen Viewed", properties: ["screen": "home"])
```

## Documentation Sections

### 📚 Getting Started
- **[Installation Guide](getting-started/installation.html)** - Add Rover 5 to your project
- **[Quick Start](getting-started/quick-start.html)** - Your first implementation
- **[Configuration](getting-started/configuration.html)** - SDK setup and options

### 🔄 Migration
- **[Migration from Rover 4](migration/from-rover-4.html)** - Step-by-step upgrade guide
- **[Breaking Changes](migration/breaking-changes.html)** - What's different in Rover 5
- **[Migration Examples](migration/examples.html)** - Before and after code samples

### 📖 API Reference
- **[Rover Class](api-reference/rover.html)** - Main SDK interface
- **[Configuration](api-reference/configuration.html)** - RoverConfiguration options
- **[Event Tracking](api-reference/event-tracking.html)** - Track method reference
- **[User Management](api-reference/user-management.html)** - User tokens and attributes

### ⚡️ Performance
- **[Benchmarks](performance/benchmarks.html)** - Performance comparisons with Rover 4
- **[Best Practices](performance/best-practices.html)** - Optimization guidelines
- **[Event Batching](performance/event-batching.html)** - How event processing works

## SDK Features

### Core Functionality
- **Event Tracking** - Functional and tracking events with auto-classification
- **User Management** - User tokens, attributes, and identification
- **Privacy Controls** - Tracking enable/disable and GDPR compliance
- **Event Batching** - Automatic batching and retry logic

### Integrations
- **Single REST Endpoint** - All events to `engage.rover.io`
- **Standard JSON Payloads** - Simple REST API integration
- **Error Handling** - Robust retry and failure handling
- **Offline Support** - Event persistence across app restarts

## Support

- **GitHub Repository**: [https://github.com/evawatts/Rover-IOS-EVA](https://github.com/evawatts/Rover-IOS-EVA)
- **Issues**: Report bugs and feature requests on GitHub
- **Email Support**: [Contact our team](mailto:support@rover.io)

---

*Ready to get started? Begin with our [Installation Guide](getting-started/installation.html).*