//
//  WindowTracker.swift
//  Amethyst
//
//  Created by Mohammed Metawea on 2026-05-19.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

import Foundation

/// Protocol for objects that want to receive callbacks about window tracking events.
protocol WindowTrackerDelegate: AnyObject {
    /// The type of application whose windows are being tracked.
    associatedtype Application: ApplicationType

    /// Called when a window is added to tracking.
    func windowTracker(
        _ tracker: WindowTracker<Application>,
        didAdd window: Application.Window,
        for application: Application
    )

    /// Called when a window is removed from tracking.
    func windowTracker(
        _ tracker: WindowTracker<Application>,
        didRemove window: Application.Window
    )
}

/// Tracks windows by their ID and by application PID.
///
/// `WindowTracker` is responsible for maintaining the set of known windows,
/// their associated applications, and the inverse mapping from application PIDs
/// to window IDs. It notifies a delegate of add and remove events.
final class WindowTracker<Application: ApplicationType> {
    // MARK: - Properties

    /// Maps a window's unique ID to the application that owns it.
    private var windowToApp: [Application.Window.WindowID: Application] = [:]

    /// Maps an application's PID to the set of window IDs it owns.
    private var appToWindows: [pid_t: Set<Application.Window.WindowID>] = [:]

    /// All windows currently tracked, keyed by ID for O(1) lookup.
    private var windowsByID: [Application.Window.WindowID: Application.Window] = [:]

    // MARK: - Public Interface

    /// Adds a window to tracking and associates it with the given application.
    ///
    /// - Parameters:
    ///   - window: The window to begin tracking.
    ///   - application: The application that owns the window.
    func add(window: Application.Window, application: Application) {
        let windowID = window.id()
        windowToApp[windowID] = application
        windowsByID[windowID] = window
        let pid = application.pid()
        if appToWindows[pid] == nil {
            appToWindows[pid] = []
        }
        appToWindows[pid]?.insert(windowID)
    }

    /// Removes a window from tracking.
    ///
    /// - Parameter window: The window to stop tracking.
    func remove(window: Application.Window) {
        let windowID = window.id()
        if let app = windowToApp[windowID] {
            let pid = app.pid()
            appToWindows[pid]?.remove(windowID)
            if appToWindows[pid]?.isEmpty == true {
                appToWindows.removeValue(forKey: pid)
            }
        }
        windowToApp.removeValue(forKey: windowID)
        windowsByID.removeValue(forKey: windowID)
    }

    /// Returns whether a given window is currently tracked.
    ///
    /// - Parameter window: The window to check.
    /// - Returns: `true` if the window is tracked, `false` otherwise.
    func isWindowTracked(_ window: Application.Window) -> Bool {
        return windowsByID[window.id()] != nil
    }

    /// Returns all windows owned by the application with the given PID.
    ///
    /// - Parameter pid: The process ID of the application.
    /// - Returns: An array of windows belonging to that application; empty if none.
    func windows(forApplicationWithPID pid: pid_t) -> [Application.Window] {
        guard let windowIDs = appToWindows[pid] else { return [] }
        return windowIDs.compactMap { windowsByID[$0] }
    }

    /// All windows currently being tracked.
    var allWindows: [Application.Window] {
        return Array(windowsByID.values)
    }
}
