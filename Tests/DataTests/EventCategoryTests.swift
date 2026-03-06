// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import XCTest
@testable import RoverData
@testable import RoverFoundation

/// Comprehensive tests for EventCategory classification system
///
/// These tests verify:
/// 1. Correct classification of all known events
/// 2. Backward compatibility with existing Event creation
/// 3. Default behavior for unknown events
/// 4. Thread safety of EventClassifier
class EventCategoryTests: XCTestCase {
    
    var classifier: EventClassifier!
    
    override func setUp() {
        super.setUp()
        classifier = EventClassifier()
    }
    
    override func tearDown() {
        classifier = nil
        super.tearDown()
    }
    
    // MARK: - Functional Event Classification Tests
    
    func testFunctionalAppLifecycleEvents() async {
        let appEvents = [
            "App Installed",
            "App Updated", 
            "App Opened",
            "App Closed",
            "App Viewed"
        ]
        
        for eventName in appEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .functional, "'\(eventName)' should be classified as functional")
            
            // Test synchronous version too
            let syncCategory = EventClassifier.classifySync(eventName)
            XCTAssertEqual(syncCategory, .functional, "Synchronous classification should match async for '\(eventName)'")
        }
    }
    
    // Location events removed - RoverLocation module deleted in clean rewrite
    
    func testFunctionalUserInteractionEvents() async {
        let interactionEvents = [
            "Screen Viewed",
            "Experience Screen Viewed",
            "Experience Button Tapped", 
            "Carousel Page Viewed"
        ]
        
        for eventName in interactionEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .functional, "'\(eventName)' should be classified as functional")
        }
    }
    
    func testFunctionalNotificationEvents() async {
        let notificationEvents = [
            "Notification Opened",
            "Notification Center Presented",
            "Notification Center Dismissed",
            "Notification Center Viewed", 
            "Notification Marked Read",
            "Notification Marked Deleted"
        ]
        
        for eventName in notificationEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .functional, "'\(eventName)' should be classified as functional")
        }
    }
    
    func testFunctionalContentEvents() async {
        let contentEvents = [
            "Post Opened",
            "Post Link Clicked"
        ]
        
        for eventName in contentEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .functional, "'\(eventName)' should be classified as functional")
        }
    }
    
    // MARK: - Tracking Event Classification Tests
    
    func testTrackingMiniAnalyticsEvents() async {
        let analyticsEvents = [
            "Experience Presented",
            "Experience Dismissed",
            "Experience Viewed",
            "Screen Presented", 
            "Screen Dismissed",
            "Block Tapped",
            "Poll Answered"
        ]
        
        for eventName in analyticsEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .tracking, "'\(eventName)' should be classified as tracking")
            
            // Test synchronous version too
            let syncCategory = EventClassifier.classifySync(eventName)
            XCTAssertEqual(syncCategory, .tracking, "Synchronous classification should match async for '\(eventName)'")
        }
    }
    
    func testTrackingErrorEvents() async {
        let errorEvents = ["Error"]
        
        for eventName in errorEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .tracking, "'\(eventName)' should be classified as tracking")
        }
    }
    
    // MARK: - Default Behavior Tests
    
    func testUnknownEventsDefaultToFunctional() async {
        let unknownEvents = [
            "Unknown Event",
            "Custom App Event", 
            "Third Party Integration",
            ""  // Edge case: empty string
        ]
        
        for eventName in unknownEvents {
            let category = await classifier.classify(eventName)
            XCTAssertEqual(category, .functional, "Unknown event '\(eventName)' should default to functional for privacy safety")
            
            // Test isMapped
            let isMapped = await classifier.isMapped(eventName)
            XCTAssertFalse(isMapped, "Unknown event '\(eventName)' should not be mapped")
        }
    }
    
    func testNamespaceHandling() async {
        // Test that namespace doesn't affect current classification
        // (future enhancement could use namespace for more specific rules)
        
        let category1 = await classifier.classify("App Opened", namespace: "rover")
        let category2 = await classifier.classify("App Opened", namespace: nil)
        let category3 = await classifier.classify("App Opened", namespace: "custom")
        
        XCTAssertEqual(category1, .functional)
        XCTAssertEqual(category2, .functional) 
        XCTAssertEqual(category3, .functional)
        XCTAssertEqual(category1, category2)
        XCTAssertEqual(category2, category3)
    }
    
    // MARK: - Event Creation Backward Compatibility Tests
    
    func testEventCreationWithoutCategory() {
        let context = Context(
            app: Context.App(build: "1", identifier: "com.test", version: "1.0"),
            device: Context.Device(
                identifier: UUID().uuidString,
                manufacturer: "Apple",
                model: "iPhone",
                name: "Test Device"
            ),
            locale: Context.Locale(
                calendar: "gregorian",
                currency: "USD", 
                language: "en",
                region: "US",
                timezone: "UTC"
            ),
            screen: Context.Screen(height: 812, width: 375),
            userAgent: "TestAgent/1.0",
            darkModeEnabled: false
        )
        
        // Test functional event auto-classification
        let functionalEvent = Event(
            name: "App Opened",
            context: context,
            namespace: "rover"
        )
        
        XCTAssertEqual(functionalEvent.category, .functional)
        XCTAssertEqual(functionalEvent.name, "App Opened")
        XCTAssertEqual(functionalEvent.namespace, "rover")
        
        // Test tracking event auto-classification
        let trackingEvent = Event(
            name: "Experience Presented", 
            context: context
        )
        
        XCTAssertEqual(trackingEvent.category, .tracking)
        XCTAssertEqual(trackingEvent.name, "Experience Presented")
        
        // Test unknown event defaults to functional
        let unknownEvent = Event(
            name: "Custom Unknown Event",
            context: context
        )
        
        XCTAssertEqual(unknownEvent.category, .functional)
    }
    
    func testEventCreationWithExplicitCategory() {
        let context = Context(
            app: Context.App(build: "1", identifier: "com.test", version: "1.0"),
            device: Context.Device(
                identifier: UUID().uuidString,
                manufacturer: "Apple",
                model: "iPhone",
                name: "Test Device"
            ),
            locale: Context.Locale(
                calendar: "gregorian",
                currency: "USD",
                language: "en", 
                region: "US",
                timezone: "UTC"
            ),
            screen: Context.Screen(height: 812, width: 375),
            userAgent: "TestAgent/1.0",
            darkModeEnabled: false
        )
        
        // Test explicit category overrides auto-classification
        let explicitFunctional = Event(
            name: "Experience Presented",  // Would normally be tracking
            context: context,
            category: .functional
        )
        
        XCTAssertEqual(explicitFunctional.category, .functional)
        
        let explicitTracking = Event(
            name: "App Opened",  // Would normally be functional  
            context: context,
            category: .tracking
        )
        
        XCTAssertEqual(explicitTracking.category, .tracking)
    }
    
    // MARK: - EventCategory Properties Tests
    
    func testEventCategoryProperties() {
        // Test functional category properties
        XCTAssertFalse(EventCategory.functional.requiresTrackingConsent)
        XCTAssertEqual(EventCategory.functional.defaultEndpointDomain, "engage.rover.io")
        XCTAssertEqual(EventCategory.functional.description, "Functional (always works)")
        
        // Test tracking category properties  
        XCTAssertTrue(EventCategory.tracking.requiresTrackingConsent)
        XCTAssertEqual(EventCategory.tracking.defaultEndpointDomain, "engage.rover.io") 
        XCTAssertEqual(EventCategory.tracking.description, "Tracking (requires ATT consent)")
    }
    
    func testEventCategoryCodable() throws {
        // Test that EventCategory can be encoded/decoded
        let functional = EventCategory.functional
        let tracking = EventCategory.tracking
        
        let functionalData = try JSONEncoder().encode(functional)
        let trackingData = try JSONEncoder().encode(tracking)
        
        let decodedFunctional = try JSONDecoder().decode(EventCategory.self, from: functionalData)
        let decodedTracking = try JSONDecoder().decode(EventCategory.self, from: trackingData)
        
        XCTAssertEqual(decodedFunctional, .functional)
        XCTAssertEqual(decodedTracking, .tracking)
    }
    
    // MARK: - EventClassifier Utility Methods Tests
    
    func testEventClassifierUtilities() async {
        let functionalEvents = await classifier.events(in: .functional)
        let trackingEvents = await classifier.events(in: .tracking)
        
        // Verify we have both types of events
        XCTAssertTrue(functionalEvents.count > 0, "Should have functional events")
        XCTAssertTrue(trackingEvents.count > 0, "Should have tracking events")
        
        // Verify some expected events are present
        XCTAssertTrue(functionalEvents.contains("App Opened"))
        XCTAssertTrue(functionalEvents.contains("Screen Viewed"))
        XCTAssertTrue(trackingEvents.contains("Experience Presented"))
        XCTAssertTrue(trackingEvents.contains("Block Tapped"))
        
        // Verify events are sorted
        XCTAssertEqual(functionalEvents, functionalEvents.sorted())
        XCTAssertEqual(trackingEvents, trackingEvents.sorted())
        
        // Test statistics
        let stats = await classifier.mappingStatistics()
        XCTAssertEqual(stats[.functional], functionalEvents.count)
        XCTAssertEqual(stats[.tracking], trackingEvents.count)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentClassification() async {
        let eventNames = [
            "App Opened", "Experience Presented", "Screen Viewed", 
            "Block Tapped", "Notification Opened", "Poll Answered"
        ]
        
        // Test concurrent access to classifier
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    
                    for eventName in eventNames {
                        let category = await self.classifier.classify(eventName)
                        
                        // Verify expected results under concurrent access
                        switch eventName {
                        case "App Opened", "Screen Viewed", "Notification Opened":
                            XCTAssertEqual(category, .functional)
                        case "Experience Presented", "Block Tapped", "Poll Answered":
                            XCTAssertEqual(category, .tracking)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Event Codable Tests
    
    func testEventWithCategoryCodable() throws {
        let context = Context(
            app: Context.App(build: "1", identifier: "com.test", version: "1.0"),
            device: Context.Device(
                identifier: UUID().uuidString,
                manufacturer: "Apple",
                model: "iPhone",
                name: "Test Device"
            ),
            locale: Context.Locale(
                calendar: "gregorian",
                currency: "USD",
                language: "en",
                region: "US", 
                timezone: "UTC"
            ),
            screen: Context.Screen(height: 812, width: 375),
            userAgent: "TestAgent/1.0",
            darkModeEnabled: false
        )
        
        let originalEvent = Event(
            name: "Test Event",
            context: context,
            namespace: "test",
            attributes: ["key": "value"],
            category: .tracking
        )
        
        // Test encoding/decoding preserves category
        let encoded = try JSONEncoder().encode(originalEvent)
        let decoded = try JSONDecoder().decode(Event.self, from: encoded)
        
        XCTAssertEqual(decoded.name, originalEvent.name)
        XCTAssertEqual(decoded.namespace, originalEvent.namespace)  
        XCTAssertEqual(decoded.category, originalEvent.category)
        XCTAssertEqual(decoded.id, originalEvent.id)
    }
}