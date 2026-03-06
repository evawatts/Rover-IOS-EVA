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

/// Configuration for Rover SDK initialization
///
/// Simple configuration struct that replaces the complex assembler system.
/// Designed to be Segment-SDK-like for ease of use.
public struct RoverConfiguration {
    /// Your Rover API key
    public let apiKey: String
    
    /// Base URL for Rover API (defaults to engage.rover.io)
    public let baseURL: String
    
    /// Whether to enable debug logging
    public let enableDebugLogging: Bool
    
    /// Custom user agent suffix (optional)
    public let userAgentSuffix: String?
    
    /// Initialize Rover configuration
    ///
    /// - Parameters:
    ///   - apiKey: Your Rover API key (required)
    ///   - baseURL: Base URL for API calls (defaults to https://engage.rover.io)
    ///   - enableDebugLogging: Enable debug logging (defaults to false)
    ///   - userAgentSuffix: Optional suffix for user agent
    public init(
        apiKey: String,
        baseURL: String = "https://engage.rover.io",
        enableDebugLogging: Bool = false,
        userAgentSuffix: String? = nil
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.enableDebugLogging = enableDebugLogging
        self.userAgentSuffix = userAgentSuffix
    }
}