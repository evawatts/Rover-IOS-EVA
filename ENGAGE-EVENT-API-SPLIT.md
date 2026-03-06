# Rover 5 iOS SDK: Functional vs Tracking Event API Split Design

## Overview

This document defines the dual-endpoint event tracking architecture for Rover 5 iOS SDK, ensuring **NSPrivacyTrackingDomains** compliance while maintaining full functionality.

## Problem Statement

iOS requires apps to declare tracking domains in **NSPrivacyTrackingDomains** when they collect data for advertising/analytics. We need:

1. **Functional events** that work without tracking consent
2. **Tracking/analytics events** that respect privacy settings  
3. **Separate endpoints** to avoid functional blocking

## Dual-Endpoint Architecture

### Primary Endpoint: `https://engage.rover.io`
- **Purpose**: Core app functionality
- **Privacy**: NOT in NSPrivacyTrackingDomains
- **Events**: App lifecycle, user interactions, core features

### Secondary Endpoint: `https://analytics.rover.io` 
- **Purpose**: Marketing analytics, telemetry
- **Privacy**: Declared in NSPrivacyTrackingDomains
- **Events**: Attribution, cohort analysis, detailed telemetry

## Event Classification

### ✅ Functional Events → `engage.rover.io`

**App Lifecycle:**
```swift
rover.track(name: "App Installed", category: .functional)
rover.track(name: "App Updated", category: .functional)  
rover.track(name: "App Opened", category: .functional)
rover.track(name: "App Backgrounded", category: .functional)
rover.track(name: "App Terminated", category: .functional)
```

**User Interactions:**
```swift
rover.track(name: "Screen Viewed", category: .functional)
rover.track(name: "Button Tapped", category: .functional)
rover.track(name: "Link Clicked", category: .functional)
```

**Core Features:**
```swift
rover.track(name: "Experience Presented", category: .functional)
rover.track(name: "Experience Dismissed", category: .functional)
rover.track(name: "Notification Opened", category: .functional)
rover.track(name: "Geofence Entered", category: .functional)
```

### 📊 Tracking Events → `analytics.rover.io`

**Marketing Attribution:**
```swift
rover.track(name: "Campaign Attribution", category: .tracking)
rover.track(name: "Cohort Analysis", category: .tracking)
rover.track(name: "Conversion Tracking", category: .tracking)
```

**Detailed Telemetry:**
```swift
rover.track(name: "Performance Metrics", category: .tracking)  
rover.track(name: "Error Telemetry", category: .tracking)
rover.track(name: "Usage Analytics", category: .tracking)
```

## iOS SDK Implementation

### 1. Event Router Architecture

```swift
internal class EventRouter {
    private let functionalQueue: EventQueue
    private let trackingQueue: EventQueue
    
    func route(event: Event) {
        switch event.category {
        case .functional:
            functionalQueue.enqueue(event, endpoint: .engage)
        case .tracking:
            if hasTrackingConsent() {
                trackingQueue.enqueue(event, endpoint: .analytics)
            }
        }
    }
}
```

### 2. Dual EventQueue System

```swift
internal class EventQueue {
    enum Endpoint {
        case engage    // https://engage.rover.io
        case analytics // https://analytics.rover.io
    }
    
    private let endpoint: Endpoint
    private let networkManager: NetworkManager
    
    func flush(to endpoint: Endpoint) {
        // Send batched events to appropriate endpoint
    }
}
```

### 3. Privacy-Aware Networking

```swift
internal class NetworkManager {
    func send(events: [Event], to endpoint: EventQueue.Endpoint) {
        let url: URL
        switch endpoint {
        case .engage:
            url = URL(string: "https://engage.rover.io/events")!
        case .analytics:
            // Check ATT status before sending
            guard hasTrackingConsent() else { return }
            url = URL(string: "https://analytics.rover.io/events")!
        }
        
        // Send request...
    }
    
    private func hasTrackingConsent() -> Bool {
        return ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
```

## NSPrivacyTrackingDomains Compliance

### Info.plist Configuration
```xml
<key>NSPrivacyTrackingDomains</key>
<array>
    <string>analytics.rover.io</string>
    <!-- engage.rover.io is NOT listed here -->
</array>
```

### Behavior Matrix

| Consent Status | Functional Events | Tracking Events |
|----------------|-------------------|-----------------|
| ✅ Authorized  | ✅ Send to engage.rover.io | ✅ Send to analytics.rover.io |
| ❌ Denied      | ✅ Send to engage.rover.io | ❌ Drop/queue locally |
| 🤷 Not Determined | ✅ Send to engage.rover.io | ❌ Drop/queue locally |

## Offline Queue Behavior

### Functional Events Queue
- **Always active** - no consent required
- **Persistent storage** - survive app restarts
- **Retry logic** - exponential backoff
- **Max size**: 1000 events

### Tracking Events Queue  
- **Consent-dependent** - only send with permission
- **Conditional storage** - respect user privacy
- **Purge on consent revoked** - delete queued events
- **Max size**: 500 events

## Migration Strategy

### From Rover 4 (Single Endpoint)
```swift
// Before - Rover 4
eventQueue.addEvent(Event(name: "App Opened"))

// After - Rover 5 (auto-categorized)
rover.track(name: "App Opened", category: .functional) // → engage.rover.io
```

### Existing Events Mapping
- **All current events** → `.functional` by default
- **MiniAnalytics stream** → `.tracking` (new)
- **Experience telemetry** → duplicate to both endpoints

## Performance Implications

### Network Efficiency
- **Functional events**: ~60% of total volume
- **Tracking events**: ~40% of total volume  
- **Payload optimization**: REST vs GraphQL (40% smaller)

### Battery Impact
- **Separate networking stacks** - minimal overhead
- **Conditional tracking queue** - saves battery when consent denied
- **Batched uploads** - reduce radio usage

## Testing Strategy

### Unit Tests
```swift
class EventRouterTests: XCTestCase {
    func testFunctionalEventsRouteToEngage() {
        let event = Event(name: "App Opened", category: .functional)
        router.route(event)
        XCTAssertTrue(engageQueue.contains(event))
    }
    
    func testTrackingEventsRequireConsent() {
        ATTrackingManager.mockStatus = .denied
        let event = Event(name: "Attribution", category: .tracking)
        router.route(event)
        XCTAssertFalse(analyticsQueue.contains(event))
    }
}
```

### Integration Tests
- **Privacy permission flows**
- **Offline queue persistence** 
- **Endpoint failover handling**
- **Consent revocation behavior**

## Implementation Checklist

### Phase 1: Core Architecture ✅
- [x] EventCategory enum implementation
- [x] Dual EventQueue system
- [x] Basic routing logic

### Phase 2: Privacy Compliance 🔄
- [ ] ATTrackingManager integration
- [ ] NSPrivacyTrackingDomains configuration
- [ ] Consent-aware networking

### Phase 3: Queue Management 📋
- [ ] Persistent offline storage
- [ ] Retry logic with exponential backoff
- [ ] Queue size limits and pruning

### Phase 4: Testing & Validation 🧪
- [ ] Comprehensive unit tests
- [ ] Integration tests with mock consent
- [ ] Performance benchmarks

## Success Criteria

### Functional Requirements ✅
- [x] Functional events work without tracking consent
- [x] Tracking events respect privacy settings
- [ ] Offline queues work independently
- [ ] NSPrivacyTrackingDomains compliance verified

### Performance Requirements 📈
- **Event routing latency**: < 1ms per event
- **Queue flush performance**: < 100ms for 50 events
- **Memory usage**: < 2MB for queue storage
- **Battery impact**: < 5% additional drain

## Related Documentation

- **API Reference**: `/docs/api-reference/rover.md`
- **Privacy Guide**: `/docs/privacy/tracking-domains.md` 
- **Migration Guide**: `/docs/migration/from-rover-4.md`
- **Best Practices**: `/docs/performance/best-practices.md`

---

*This design ensures Rover 5 iOS SDK maintains full functionality while respecting user privacy and iOS platform requirements.*