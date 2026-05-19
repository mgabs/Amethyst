//
//  ApplicationMonitor.swift
//  Amethyst
//
//  Created by Mohammed Metawea on 2026-05-19.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

import Foundation

/// Protocol for objects that want to receive callbacks about application lifecycle events.
protocol ApplicationMonitorDelegate: AnyObject {
    /// The type of application being monitored.
    associatedtype Application: ApplicationType

    /// Called when an application is launched and added to tracking.
    func applicationMonitor(_ monitor: ApplicationMonitor<Application>, didLaunch application: Application)

    /// Called when an application terminates and is removed from tracking.
    func applicationMonitor(_ monitor: ApplicationMonitor<Application>, didTerminate application: Application)

    /// Called when an application becomes active/frontmost.
    func applicationMonitor(_ monitor: ApplicationMonitor<Application>, didActivate application: Application)
}

/// Tracks running applications by PID and delivers lifecycle callbacks.
///
/// `ApplicationMonitor` is responsible for managing the set of known applications.
/// It tracks applications keyed by their process ID and notifies a delegate of
/// launch, termination, and activation events.
final class ApplicationMonitor<Application: ApplicationType> {
    // MARK: - Properties

    /// Applications tracked by their process ID.
    private var applications: [pid_t: Application] = [:]

    // MARK: - Public Interface

    /// Adds an application to tracking.
    ///
    /// - Parameter application: The application to begin tracking.
    func add(application: Application) {
        applications[application.pid()] = application
    }

    /// Removes an application from tracking.
    ///
    /// - Parameter application: The application to stop tracking.
    func remove(application: Application) {
        applications.removeValue(forKey: application.pid())
    }

    /// Returns the tracked application with the given PID, if any.
    ///
    /// - Parameter pid: The process ID to look up.
    /// - Returns: The application with the given PID, or `nil` if not tracked.
    func application(withPID pid: pid_t) -> Application? {
        return applications[pid]
    }
}
