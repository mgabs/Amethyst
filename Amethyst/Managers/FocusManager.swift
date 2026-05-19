//
//  FocusManager.swift
//  Amethyst
//
//  Created by Mohammed Metawea on 2026-05-19.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

import Foundation

// MARK: - Delegate Protocol

protocol FocusManagerDelegate: AnyObject {
    associatedtype Window: WindowType

    func focusManager(didChangeFocusFrom oldWindow: Window?, to newWindow: Window?)
}

// MARK: - FocusManager

/// Manages focus state and transitions for windows.
/// Tracks last focused window, focus timestamp, and notifies a delegate on changes.
final class FocusManager<Application: ApplicationType> {
    typealias Window = Application.Window

    // MARK: Properties

    /// The most recently focused window, or nil if focus has been cleared.
    private(set) var lastFocusedWindow: Window?

    /// The date when focus was last set.
    private var lastFocusDate: Date?

    // MARK: Focus State

    /// Set the currently focused window.
    /// Updates `lastFocusedWindow`, records the focus timestamp.
    func setFocused(window: Window) {
        lastFocusedWindow = window
        lastFocusDate = Date()
    }

    /// Clear current focus state.
    /// Resets `lastFocusedWindow` and `lastFocusDate` to nil.
    func clearFocus() {
        lastFocusedWindow = nil
        lastFocusDate = nil
    }

    /// Time interval since the last focus event, or `.infinity` if never focused.
    var timeSinceLastFocus: TimeInterval {
        guard let lastFocusDate else { return .infinity }
        return Date().timeIntervalSince(lastFocusDate)
    }

    /// Returns `true` if the given window is the currently tracked focused window.
    func isFocused(window: Window) -> Bool {
        return lastFocusedWindow == window
    }
}
