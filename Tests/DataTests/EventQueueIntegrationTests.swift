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

/// Integration tests for EventQueue with EventCategory system
///
/// These tests verify that the existing EventQueue functionality continues to work
/// with the new EventCategory classification system, ensuring no regressions.
class EventQueueIntegrationTests: XCTestCase {
    
    var eventQueue: EventQueue!
    var mockClient: MockEventsClient!
    var contextProvider: MockContextProvider!
    
    override func setUp() {
        super.setUp()
        
        mockClient = MockEventsClient()
        contextProvider = MockContextProvider()
        
        eventQueue = EventQueue(
            client: mockClient,
            flushAt: 1,  // Flush immediately for testing
            flushInterval: 0.1,
            maxBatchSize: 10,
            maxQueueSize: 100
        )
        
        eventQueue.contextProvider = contextProvider
    }
    
    override func tearDown() {
        eventQueue = nil
        mockClient = nil
        contextProvider = nil
        super.tearDown()
    }
    
    // MARK: - Regression Tests - Existing Functionality Preserved
    
    func testAddEventWithAutoClassification() {
        let expectation = expectation(description: "Event should be added and classified")
        
        // Create EventInfo as before (existing API)
        let eventInfo = EventInfo(
            name: "App Opened",
            namespace: "rover",
            attributes: ["test": "value"]
        )
        
        // Mock client should capture the event
        mockClient.eventHandler = { events in
            XCTAssertEqual(events.count, 1)
            
            let event = events.first!
            XCTAssertEqual(event.name, "App Opened")
            XCTAssertEqual(event.namespace, "rover")
            XCTAssertEqual(event.category, .functional)  // Should be auto-classified
            
            expectation.fulfill()
        }
        
        // Add event using existing API - should work identically
        eventQueue.addEvent(eventInfo)
        
        // Trigger flush
        eventQueue.flush()
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testFunctionalEventClassification() {
        let expectation = expectation(description: "Functional events should be classified correctly")
        
        let functionalEvents = [
            EventInfo(name: "App Installed", namespace: "rover"),
            EventInfo(name: "App Opened", namespace: "rover"),
            EventInfo(name: "Screen Viewed", attributes: ["screenName": "Home"]),
            EventInfo(name: "Notification Opened", namespace: "rover")
        ]
        
        mockClient.eventHandler = { events in
            XCTAssertEqual(events.count, functionalEvents.count)
            
            for event in events {
                XCTAssertEqual(event.category, .functional, "Event '\(event.name)' should be classified as functional")
            }
            
            expectation.fulfill()
        }
        
        // Add events using existing API
        for eventInfo in functionalEvents {
            eventQueue.addEvent(eventInfo)
        }
        
        eventQueue.flush()
        waitForExpectations(timeout: 1.0)
    }
    
    func testTrackingEventClassification() {
        let expectation = expectation(description: "Tracking events should be classified correctly")
        
        let trackingEvents = [
            EventInfo(name: "Experience Presented", namespace: "rover"),
            EventInfo(name: "Block Tapped", namespace: "rover"),
            EventInfo(name: "Poll Answered", namespace: "rover")
        ]
        
        mockClient.eventHandler = { events in
            XCTAssertEqual(events.count, trackingEvents.count)
            
            for event in events {
                XCTAssertEqual(event.category, .tracking, "Event '\(event.name)' should be classified as tracking")
            }
            
            expectation.fulfill()
        }
        
        // Add events using existing API
        for eventInfo in trackingEvents {
            eventQueue.addEvent(eventInfo)
        }
        
        eventQueue.flush()
        waitForExpectations(timeout: 1.0)
    }
    
    func testUnknownEventsDefaultToFunctional() {
        let expectation = expectation(description: "Unknown events should default to functional")
        
        let unknownEvents = [
            EventInfo(name: "Custom App Event"),
            EventInfo(name: "Third Party Integration", namespace: "custom"),
            EventInfo(name: "Unknown Event", attributes: ["custom": "attribute"])
        ]
        
        mockClient.eventHandler = { events in
            XCTAssertEqual(events.count, unknownEvents.count)
            
            for event in events {
                XCTAssertEqual(event.category, .functional, "Unknown event '\(event.name)' should default to functional")
            }
            
            expectation.fulfill()
        }
        
        // Add events using existing API
        for eventInfo in unknownEvents {
            eventQueue.addEvent(eventInfo)
        }
        
        eventQueue.flush()
        waitForExpectations(timeout: 1.0)
    }
    
    func testScreenTrackingConvenienceMethodPreserved() {
        let expectation = expectation(description: "Screen tracking method should work with classification")
        
        mockClient.eventHandler = { events in
            XCTAssertEqual(events.count, 1)
            
            let event = events.first!
            XCTAssertEqual(event.name, "Screen Viewed")
            XCTAssertEqual(event.category, .functional)  // Screen Viewed is functional
            
            if let attributes = event.attributes {
                XCTAssertEqual(attributes["screenName"] as? String, "Home")
                XCTAssertEqual(attributes["contentID"] as? String, "home-123")
            } else {
                XCTFail("Event should have attributes")
            }
            
            expectation.fulfill()
        }
        
        // Use existing convenience method
        eventQueue.trackScreenViewed(
            screenName: "Home",
            contentID: "home-123",
            contentName: "Home Screen"
        )
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Event Serialization with Category
    
    func testEventSerializationIncludesCategory() {
        let expectation = expectation(description: "Serialized events should include category")
        
        let eventInfo = EventInfo(
            name: "Experience Presented",
            namespace: "rover",
            attributes: ["experienceId": "123"]
        )
        
        mockClient.eventHandler = { events in
            let event = events.first!
            
            do {
                // Test that event can be serialized with category
                let encoder = JSONEncoder()
                let data = try encoder.encode(event)
                
                let decoder = JSONDecoder()
                let decodedEvent = try decoder.decode(Event.self, from: data)
                
                XCTAssertEqual(decodedEvent.name, event.name)
                XCTAssertEqual(decodedEvent.category, event.category)
                XCTAssertEqual(decodedEvent.category, .tracking)
                
                expectation.fulfill()
            } catch {
                XCTFail("Event serialization failed: \(error)")
            }
        }
        
        eventQueue.addEvent(eventInfo)
        eventQueue.flush()
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testExistingEventCreationPatternsStillWork() {
        // Test various existing event creation patterns from the codebase
        
        // Pattern 1: Simple event with name and namespace
        let appOpenedEvent = Event(
            name: "App Opened",
            context: contextProvider.context,
            namespace: "rover"
        )
        XCTAssertEqual(appOpenedEvent.category, .functional)
        
        // Pattern 2: Event with attributes
        let screenViewedEvent = Event(
            name: "Experience Screen Viewed",
            context: contextProvider.context,
            namespace: "rover",
            attributes: ["screenId": "123"]
        )
        XCTAssertEqual(screenViewedEvent.category, .functional)
        
        // Pattern 3: Event with timestamp
        let customTimestamp = Date(timeIntervalSince1970: 1640995200)
        let timedEvent = Event(
            name: "Block Tapped",
            context: contextProvider.context,
            timestamp: customTimestamp
        )
        XCTAssertEqual(timedEvent.category, .tracking)
        XCTAssertEqual(timedEvent.timestamp, customTimestamp)
    }
}

// MARK: - Mock Classes

class MockEventsClient: EventsClient {
    var eventHandler: (([Event]) -> Void)?
    var shouldReturnError: Bool = false
    var capturedEvents: [Event] = []
    
    func sendEvents(with events: [Event]) async -> HTTPResult {
        capturedEvents.append(contentsOf: events)
        eventHandler?(events)
        
        if shouldReturnError {
            return .error(error: MockError(), isRetryable: false)
        } else {
            let responseData = """
                {
                    "data": {
                        "trackEvents": "success"
                    }
                }
                """.data(using: .utf8)!
            
            return .success(data: responseData, response: nil)
        }
    }
}

class MockContextProvider: ContextProvider {
    var context: Context {
        return Context(
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
    }
}

struct MockError: Error {
    let localizedDescription = "Mock error for testing"
}