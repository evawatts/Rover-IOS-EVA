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

import Foundation

/// Example usage of the clean Rover 5 API
///
/// This file demonstrates the dramatically simplified interface compared to Rover 4.
/// No complex assemblers, no dependency injection - just simple, clean initialization and tracking.
public class RoverExample {
    
    /// Example: Simple initialization (replaces complex assembler system)
    public static func initializeRover() {
        // Clean, Segment-inspired initialization
        let rover = Rover(configuration: RoverConfiguration(
            apiKey: "your-api-key",
            baseURL: "https://engage.rover.io",
            enableDebugLogging: true
        ))
        
        // Store reference if needed
        // In a real app, you'd typically store this in your AppDelegate or similar
        _ = rover
    }
    
    /// Example: Event tracking with explicit categories
    public static func trackEventsWithCategories(rover: Rover) {
        // Tracking events (require ATT consent)
        rover.track(name: "Experience Presented", category: .tracking)
        rover.track(name: "Screen Presented", category: .tracking)
        rover.track(name: "Block Tapped", category: .tracking)
        
        // Functional events (always work)
        rover.track(name: "App Opened", category: .functional)
        rover.track(name: "Screen Viewed", category: .functional)
        rover.track(name: "Notification Opened", category: .functional)
    }
    
    /// Example: Event tracking with automatic classification
    public static func trackEventsWithAutoClassification(rover: Rover) {
        // These events are automatically classified by EventClassifier
        rover.track(name: "Experience Presented")  // -> .tracking
        rover.track(name: "App Opened")            // -> .functional
        rover.track(name: "Screen Viewed")         // -> .functional
        rover.track(name: "Block Tapped")          // -> .tracking
    }
    
    /// Example: Event tracking with properties
    public static func trackEventsWithProperties(rover: Rover) {
        // E-commerce example
        rover.track(
            name: "Purchase",
            category: .tracking,
            properties: [
                "value": 49.99,
                "currency": "USD",
                "item_id": "shirt-123",
                "category": "clothing"
            ]
        )
        
        // Content interaction example
        rover.track(
            name: "Screen Viewed",
            category: .functional,
            properties: [
                "screen_name": "product_detail",
                "product_id": "shirt-123"
            ]
        )
    }
    
    /// Example: User management (simplified)
    public static func manageUsers(rover: Rover) {
        // Set user token (JWT)
        rover.setUserToken("eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...")
        
        // Set user attributes
        rover.setUserAttributes([
            "user_id": "12345",
            "email": "user@example.com",
            "plan": "premium"
        ])
        
        // Clear user token (logout)
        rover.setUserToken(nil)
    }
    
    /// Example: Privacy controls
    public static func managePrivacy(rover: Rover) {
        // Enable/disable tracking
        rover.setTrackingEnabled(true)   // Enable analytics
        rover.setTrackingEnabled(false)  // Disable analytics (functional events still work)
    }
}

// MARK: - Migration Example

/// Example showing the difference between Rover 4 and Rover 5
public class MigrationExample {
    
    /// Rover 4: Complex assembler-based initialization
    public static func rover4Style() {
        // OLD WAY (Rover 4) - Complex assemblers
        /*
        let assemblers: [Assembler] = [
            FoundationAssembler(),
            DataAssembler(apiEndpoint: "https://api.rover.io/graphql"),
            UIAssembler(),
            ExperiencesAssembler(),
            NotificationsAssembler()
        ]
        
        Rover.initialize(assemblers: assemblers)
        
        // Tracking required complex dependency resolution
        Rover.shared.eventQueue.addEvent(
            Event(name: "Experience Presented", context: context, category: .tracking)
        )
        */
    }
    
    /// Rover 5: Clean, simple initialization
    public static func rover5Style() {
        // NEW WAY (Rover 5) - Simple initialization
        let rover = Rover(configuration: RoverConfiguration(
            apiKey: "your-api-key",
            baseURL: "https://engage.rover.io"
        ))
        
        // Simple event tracking
        rover.track(name: "Experience Presented", category: .tracking)
        rover.track(name: "App Opened", category: .functional)
        rover.track(name: "Purchase", properties: ["value": 49.99])
    }
}