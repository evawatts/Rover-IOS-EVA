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
import RoverData
import os.log

/// REST-based events client for engage.rover.io
///
/// Replaces GraphQL-based events client with simple REST API calls.
/// Designed for the clean Rover 5 SDK architecture.
public class EngageEventsClient {
    
    private let baseURL: URL
    private let apiKey: String
    private let logger = OSLog(subsystem: "io.rover.sdk", category: "EngageEventsClient")
    private let session: URLSession
    
    /// Initialize the engage events client
    ///
    /// - Parameters:
    ///   - baseURL: Base URL for engage.rover.io
    ///   - apiKey: API key for authentication
    public init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        // Configure URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    /// Send events to engage.rover.io REST API
    ///
    /// - Parameter events: Array of events to send
    /// - Returns: HTTPResult indicating success or failure
    public func sendEvents(_ events: [Event]) async -> HTTPResult {
        guard !events.isEmpty else {
            return HTTPResult.success(data: Data(), response: HTTPURLResponse())
        }
        
        // Create REST endpoint URL
        let eventsURL = baseURL.appendingPathComponent("v1/events")
        
        // Create request
        var request = URLRequest(url: eventsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create payload
        let payload = EngageEventsPayload(events: events)
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            os_log("Sending %d events to %@", log: logger, type: .info, events.count, eventsURL.absoluteString)
            
            // Send request
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    os_log("Successfully sent events (status: %d)", log: logger, type: .info, httpResponse.statusCode)
                    return HTTPResult.success(data: data, response: httpResponse)
                } else {
                    os_log("Failed to send events (status: %d)", log: logger, type: .error, httpResponse.statusCode)
                    let isRetryable = httpResponse.statusCode >= 500 || httpResponse.statusCode == 429
                    return HTTPResult.error(error: HTTPError(statusCode: httpResponse.statusCode), isRetryable: isRetryable)
                }
            } else {
                os_log("Invalid response type", log: logger, type: .error)
                return HTTPResult.error(error: InvalidResponseError(), isRetryable: true)
            }
            
        } catch {
            os_log("Network error: %@", log: logger, type: .error, error.localizedDescription)
            return HTTPResult.error(error: error, isRetryable: true)
        }
    }
}

// MARK: - Payload Structures

/// Payload structure for engage.rover.io REST API
private struct EngageEventsPayload: Codable {
    let events: [Event]
    let timestamp: Date
    let version: String
    
    init(events: [Event]) {
        self.events = events
        self.timestamp = Date()
        self.version = "5.0.0"
    }
}

// MARK: - Error Types

private struct HTTPError: Error {
    let statusCode: Int
}

private struct InvalidResponseError: Error {}

// MARK: - HTTPResult Support

/// Simple HTTP result enum for engage client
public enum HTTPResult {
    case success(data: Data, response: HTTPURLResponse)
    case error(error: Error, isRetryable: Bool)
}