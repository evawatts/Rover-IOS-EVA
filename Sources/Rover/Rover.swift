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
import RoverFoundation
import RoverData
import os.log

/// Clean Rover 5 SDK - Segment-inspired simple interface
///
/// Provides a dramatically simpler API than Rover 4, with single engage.rover.io endpoint
/// and no complex assembler system.
///
/// Usage:
/// ```swift
/// let rover = Rover(configuration: RoverConfiguration(
///     apiKey: "your-api-key",
///     baseURL: "https://engage.rover.io"
/// ))
///
/// rover.track(name: "Experience Presented", category: .tracking)
/// rover.track(name: "App Opened", category: .functional)
/// rover.track(name: "Purchase", properties: ["value": 49.99])
/// ```
public class Rover {
    
    // MARK: - Configuration
    
    /// Current configuration
    public let configuration: RoverConfiguration
    
    // MARK: - Internal Components
    
    private let eventQueue: SimpleEventQueue
    private let context: Context
    private let logger = OSLog(subsystem: "io.rover.sdk", category: "Rover")
    
    // MARK: - Initialization
    
    /// Initialize Rover with simple configuration
    ///
    /// - Parameter configuration: RoverConfiguration with API key and settings
    public init(configuration: RoverConfiguration) {
        self.configuration = configuration
        
        // Create context (device info, etc.)
        self.context = Context(
            appIdentifier: Bundle.main.bundleIdentifier ?? "unknown",
            buildIdentifier: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            isDebug: configuration.enableDebugLogging,
            versionIdentifier: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
        
        // Create simple event queue with engage.rover.io endpoint
        self.eventQueue = SimpleEventQueue(
            baseURL: URL(string: configuration.baseURL)!,
            apiKey: configuration.apiKey
        )
        
        if configuration.enableDebugLogging {
            os_log("Rover initialized with baseURL: %@", log: logger, type: .info, configuration.baseURL)
        }
    }
    
    // MARK: - Event Tracking
    
    /// Track an event with explicit category
    ///
    /// - Parameters:
    ///   - name: Event name (e.g., "Experience Presented")
    ///   - category: Event category (.functional or .tracking)
    ///   - properties: Optional event properties/attributes
    ///   - namespace: Optional namespace for the event
    public func track(
        name: String,
        category: EventCategory,
        properties: [String: Any]? = nil,
        namespace: String? = nil
    ) {
        let attributes: Attributes? = properties?.mapValues { value in
            AttributeValue(value: value)
        }
        
        let event = Event(
            name: name,
            context: context,
            namespace: namespace,
            attributes: attributes,
            timestamp: Date(),
            category: category
        )
        
        eventQueue.addEvent(event)
        
        if configuration.enableDebugLogging {
            os_log("Tracked event: %@ [%@]", log: logger, type: .info, name, category.rawValue)
        }
    }
    
    /// Track an event with automatic category classification
    ///
    /// Uses EventClassifier to automatically determine if event is functional or tracking.
    /// This is backward-compatible with existing event names.
    ///
    /// - Parameters:
    ///   - name: Event name (e.g., "App Opened", "Experience Presented")
    ///   - properties: Optional event properties/attributes
    ///   - namespace: Optional namespace for the event
    public func track(
        name: String,
        properties: [String: Any]? = nil,
        namespace: String? = nil
    ) {
        let category = EventClassifier.classifySync(name, namespace: namespace)
        track(name: name, category: category, properties: properties, namespace: namespace)
    }
    
    // MARK: - User Management
    
    /// Set user identification token
    ///
    /// - Parameter token: JWT token for the authenticated user
    public func setUserToken(_ token: String?) {
        // TODO: Implement user token management with engage.rover.io
        if configuration.enableDebugLogging {
            let status = token != nil ? "set" : "cleared"
            os_log("User token %@", log: logger, type: .info, status)
        }
    }
    
    /// Set user attributes
    ///
    /// - Parameter attributes: Dictionary of user attributes
    public func setUserAttributes(_ attributes: [String: Any]) {
        // TODO: Implement user attribute management with engage.rover.io
        if configuration.enableDebugLogging {
            os_log("User attributes updated: %d keys", log: logger, type: .info, attributes.count)
        }
    }
    
    // MARK: - Privacy & Tracking
    
    /// Set tracking consent status
    ///
    /// - Parameter enabled: Whether tracking is enabled
    public func setTrackingEnabled(_ enabled: Bool) {
        // TODO: Implement privacy/tracking consent with engage.rover.io
        if configuration.enableDebugLogging {
            os_log("Tracking %@", log: logger, type: .info, enabled ? "enabled" : "disabled")
        }
    }
}