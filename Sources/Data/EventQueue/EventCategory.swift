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

/// Privacy compliance categories for event tracking
///
/// This enum classifies events based on iOS privacy requirements:
/// - **Functional**: Essential app functionality events that work without tracking consent
/// - **Tracking**: Analytics/marketing events that require App Tracking Transparency consent
///
/// All events route to the single engage.rover.io REST endpoint.
public enum EventCategory: String, CaseIterable, Codable {
    /// Functional events that work without tracking consent
    ///
    /// These events are essential for app functionality and user experience:
    /// - App lifecycle events (installed, opened, closed, etc.)
    /// - User interactions (screen views, button taps, etc.)
    /// - Experience interactions (screen views, button taps, etc.)
    /// - Notification interactions
    ///
    /// All events route to: engage.rover.io REST API
    case functional
    
    /// Tracking events subject to App Tracking Transparency
    ///
    /// These events are used for analytics, marketing, and tracking purposes:
    /// - MiniAnalytics stream events
    /// - Analytics events for measurement
    /// - Error tracking and performance monitoring
    ///
    /// Route to: engage.rover.io REST API
    /// Requires: ATTrackingManager authorization when status is not .authorized
    case tracking
}

/// Event classification mapping system for privacy compliance
///
/// This actor provides thread-safe, deterministic classification of events based on
/// their name and namespace. All events route to engage.rover.io REST endpoint,
/// but categorization remains important for privacy compliance and analytics.
public actor EventClassifier {
    
    /// Canonical mapping of event names to categories
    /// 
    /// Based on Rover 5 SDK privacy compliance requirements:
    /// - Functional events always work (no ATT consent required)
    /// - Tracking events respect ATT permissions
    ///
    /// All events route to engage.rover.io REST endpoint in clean rewrite.
    private static let eventCategoryMapping: [String: EventCategory] = [
        // MARK: - Functional Events (Always work)
        
        // App Lifecycle
        "App Installed": .functional,
        "App Updated": .functional,
        "App Opened": .functional,
        "App Closed": .functional,
        "App Viewed": .functional,
        
        // User Interactions
        "Screen Viewed": .functional,
        "Experience Screen Viewed": .functional,
        "Experience Button Tapped": .functional,
        "Carousel Page Viewed": .functional,
        
        // Notifications
        "Notification Opened": .functional,
        "Notification Center Presented": .functional,
        "Notification Center Dismissed": .functional,
        "Notification Center Viewed": .functional,
        "Notification Marked Read": .functional,
        "Notification Marked Deleted": .functional,
        
        // Content Interactions
        "Post Opened": .functional,
        "Post Link Clicked": .functional,
        
        // MARK: - Tracking Events (ATT-subject)
        
        // MiniAnalytics Events
        "Experience Presented": .tracking,
        "Experience Dismissed": .tracking,
        "Experience Viewed": .tracking,
        "Screen Presented": .tracking,
        "Screen Dismissed": .tracking,
        "Block Tapped": .tracking,
        "Poll Answered": .tracking,
        
        // Error and Performance Tracking
        "Error": .tracking,
    ]
    
    /// Default category for unmapped events (fail-safe to functional)
    private static let defaultCategory: EventCategory = .functional
    
    /// Synchronous classification for backward compatibility
    ///
    /// - Parameters:
    ///   - eventName: The name of the event to classify
    ///   - namespace: Optional namespace for context
    /// - Returns: EventCategory (.functional or .tracking)
    ///
    /// This static method provides synchronous classification for use in
    /// Event initializers and other synchronous contexts.
    public static func classifySync(_ eventName: String, namespace: String? = nil) -> EventCategory {
        return eventCategoryMapping[eventName] ?? defaultCategory
    }
    
    /// Classify an event based on its name and optional namespace
    ///
    /// - Parameters:
    ///   - eventName: The name of the event to classify
    ///   - namespace: Optional namespace for context (currently unused but available for future enhancement)
    /// - Returns: EventCategory (.functional or .tracking)
    ///
    /// This method provides deterministic classification based on the canonical mapping.
    /// Events not found in the mapping default to .functional for privacy safety.
    public func classify(_ eventName: String, namespace: String? = nil) -> EventCategory {
        // For future enhancement, namespace could be used for more specific classification
        // e.g., "rover" namespace might have different rules than nil namespace
        
        return Self.eventCategoryMapping[eventName] ?? Self.defaultCategory
    }
    
    /// Get all events mapped to a specific category
    ///
    /// - Parameter category: The category to filter by
    /// - Returns: Array of event names in that category
    ///
    /// Useful for testing and validation
    public func events(in category: EventCategory) -> [String] {
        return Self.eventCategoryMapping.compactMap { entry in
            entry.value == category ? entry.key : nil
        }.sorted()
    }
    
    /// Check if a specific event is mapped
    ///
    /// - Parameter eventName: The event name to check
    /// - Returns: true if the event has an explicit mapping, false if it would use default
    public func isMapped(_ eventName: String) -> Bool {
        return Self.eventCategoryMapping[eventName] != nil
    }
    
    /// Get statistics about the mapping
    ///
    /// - Returns: Dictionary with category counts
    public func mappingStatistics() -> [EventCategory: Int] {
        var stats: [EventCategory: Int] = [:]
        
        for category in EventCategory.allCases {
            stats[category] = Self.eventCategoryMapping.values.filter { $0 == category }.count
        }
        
        return stats
    }
}

// MARK: - EventCategory Extensions

public extension EventCategory {
    /// Human-readable description
    var description: String {
        switch self {
        case .functional:
            return "Functional (always works)"
        case .tracking:
            return "Tracking (requires ATT consent)"
        }
    }
    
    /// Whether this category requires tracking consent
    var requiresTrackingConsent: Bool {
        switch self {
        case .functional:
            return false
        case .tracking:
            return true
        }
    }
    
    /// Default endpoint domain for this category
    ///
    /// Clean rewrite uses single engage.rover.io endpoint for all events.
    var defaultEndpointDomain: String {
        return "engage.rover.io"
    }
}