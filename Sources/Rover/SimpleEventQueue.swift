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
import UIKit
import os.log

/// Simplified event queue for Rover 5 clean API
///
/// Provides event queuing, batching, and upload to engage.rover.io
/// without the complexity of the original EventQueue system.
public class SimpleEventQueue {
    
    // MARK: - Configuration
    
    private let client: EngageEventsClient
    private let flushAt: Int
    private let flushInterval: TimeInterval
    private let maxQueueSize: Int
    private let logger = OSLog(subsystem: "io.rover.sdk", category: "SimpleEventQueue")
    
    // MARK: - State
    
    private let queue = DispatchQueue(label: "io.rover.eventqueue", qos: .utility)
    private var events: [Event] = []
    private var flushTimer: Timer?
    private var isUploading = false
    
    // MARK: - Lifecycle Observers
    
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var didEnterBackgroundObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    /// Initialize the simple event queue
    ///
    /// - Parameters:
    ///   - baseURL: Base URL for engage.rover.io
    ///   - apiKey: API key for authentication
    ///   - flushAt: Number of events that triggers automatic flush (default: 20)
    ///   - flushInterval: Time interval between automatic flushes (default: 30 seconds)
    ///   - maxQueueSize: Maximum number of events to keep in queue (default: 1000)
    public init(
        baseURL: URL,
        apiKey: String,
        flushAt: Int = 20,
        flushInterval: TimeInterval = 30,
        maxQueueSize: Int = 1000
    ) {
        self.client = EngageEventsClient(baseURL: baseURL, apiKey: apiKey)
        self.flushAt = flushAt
        self.flushInterval = flushInterval
        self.maxQueueSize = maxQueueSize
        
        setupAppLifecycleObservers()
        startFlushTimer()
        restorePersistedEvents()
    }
    
    deinit {
        removeAppLifecycleObservers()
        flushTimer?.invalidate()
    }
    
    // MARK: - Public API
    
    /// Add an event to the queue
    ///
    /// - Parameter event: Event to add to the queue
    public func addEvent(_ event: Event) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.events.append(event)
            
            // Enforce max queue size
            if self.events.count > self.maxQueueSize {
                let removeCount = self.events.count - self.maxQueueSize
                self.events.removeFirst(removeCount)
                os_log("Queue size limit exceeded, removed %d oldest events", log: self.logger, type: .info, removeCount)
            }
            
            // Auto-flush if we hit the flush threshold
            if self.events.count >= self.flushAt {
                self.flush()
            }
            
            self.persistEvents()
        }
    }
    
    /// Manually flush all queued events
    public func flush() {
        queue.async { [weak self] in
            self?.uploadEvents()
        }
    }
    
    // MARK: - Private Methods
    
    private func uploadEvents() {
        guard !isUploading, !events.isEmpty else { return }
        
        isUploading = true
        let eventsToSend = events
        
        os_log("Uploading %d events", log: logger, type: .info, eventsToSend.count)
        
        Task { [weak self] in
            guard let self = self else { return }
            
            let result = await self.client.sendEvents(eventsToSend)
            
            await MainActor.run {
                self.queue.async {
                    self.isUploading = false
                    
                    switch result {
                    case .success:
                        // Remove successfully sent events
                        let sentCount = eventsToSend.count
                        if self.events.count >= sentCount {
                            self.events.removeFirst(sentCount)
                            self.persistEvents()
                        }
                        os_log("Successfully uploaded %d events", log: self.logger, type: .info, sentCount)
                        
                    case .error(let error, let isRetryable):
                        os_log("Failed to upload events: %@ (retryable: %@)", 
                               log: self.logger, type: .error, 
                               error.localizedDescription, 
                               isRetryable ? "yes" : "no")
                        
                        // For non-retryable errors, remove the events to prevent infinite retries
                        if !isRetryable {
                            let droppedCount = eventsToSend.count
                            if self.events.count >= droppedCount {
                                self.events.removeFirst(droppedCount)
                                self.persistEvents()
                            }
                            os_log("Dropped %d events due to non-retryable error", log: self.logger, type: .error, droppedCount)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - App Lifecycle
    
    private func setupAppLifecycleObservers() {
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startFlushTimer()
        }
        
        didEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flush()
        }
    }
    
    private func removeAppLifecycleObservers() {
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Timer Management
    
    private func startFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }
    
    // MARK: - Persistence
    
    private var persistenceURL: URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("rover-events-v5.json")
    }
    
    private func persistEvents() {
        guard let url = persistenceURL else { return }
        
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: url)
        } catch {
            os_log("Failed to persist events: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func restorePersistedEvents() {
        guard let url = persistenceURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let restoredEvents = try JSONDecoder().decode([Event].self, from: data)
            
            queue.async { [weak self] in
                self?.events = restoredEvents
                os_log("Restored %d persisted events", log: self?.logger ?? OSLog.disabled, type: .info, restoredEvents.count)
            }
        } catch {
            os_log("Failed to restore persisted events: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
}