//
//  Windows.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 9/15/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Foundation
import Silica

extension WindowManager {
    class Windows {
        private(set) var windows: [Window] = [] {
            didSet {
                // Rebuilt on every mutation; mutations are rare, lookups run per frame assignment.
                // First entry wins on a duplicate ID, matching the linear scan this replaced.
                windowsByID = Dictionary(windows.map { ($0.id(), $0) }, uniquingKeysWith: { first, _ in first })
            }
        }
        private var windowsByID: [Window.WindowID: Window] = [:]
        private(set) var lastMainWindows: [CGSSpaceID: Window?] = [:]
        private var activeIDCache: Set<CGWindowID> = Set()
        private var deactivatedPIDs: Set<pid_t> = Set()
        private var floatingMap: [Window.WindowID: Bool] = [:]

        // MARK: Window Filters

        func window(withID id: Window.WindowID) -> Window? {
            return windowsByID[id]
        }

        func windows(forApplicationWithPID applicationPID: pid_t) -> [Window] {
            return windows.filter { $0.pid() == applicationPID }
        }

        func windows(onScreen screen: Screen) -> [Window] {
            return windows.filter { $0.screen() == screen }
        }

        func activeWindows(onScreen screen: Screen) -> [Window] {
            guard let screenID = screen.screenID() else {
                return []
            }

            guard let currentSpace = screen.currentSpace() else {
                log.warning("Could not find a space for screen: \(screenID)")
                return []
            }

            return activeWindows(matchingScreenID: screenID, spaceID: currentSpace.id)
        }

        func activeWindows(onScreen screen: Screen, onSpace spaceID: CGSSpaceID) -> [Window] {
            guard let screenID = screen.screenID() else {
                return []
            }

            return activeWindows(matchingScreenID: screenID, spaceID: spaceID)
        }

        private func activeWindows(matchingScreenID screenID: String, spaceID: CGSSpaceID) -> [Window] {
            return windows.filter { window in
                // In-memory checks first.
                guard !isWindowFloating(window), !isWindowHidden(window), activeIDCache.contains(window.cgID()) else {
                    return false
                }

                // Window-server and accessibility round trips only for the survivors.
                guard window.spaceID() == spaceID, window.isActive() else {
                    return false
                }

                return window.screen()?.screenID() == screenID
            }
        }

        func activeWindowOnCurrentScreen(atIndex: Int) -> Window? {
            guard let focusedWindow = Window.currentlyFocused(),
                  let currentScreen = focusedWindow.screen() else {
                return nil
            }
            let activeWindows = activeWindows(onScreen: currentScreen)

            return activeWindows.indices.contains(atIndex) ? activeWindows[atIndex] : nil
        }

        // MARK: Adding and Removing

        func add(window: Window, atFront shouldInsertAtFront: Bool) {
            if shouldInsertAtFront {
                if let currentFocusedSpace = Window.currentFocusedSpace(),
                   let firstActiveWindow = activeWindowOnCurrentScreen(atIndex: 0) {
                    lastMainWindows[currentFocusedSpace.id] = firstActiveWindow
                }

                windows.insert(window, at: 0)
            } else {
                windows.append(window)
            }
        }

        func add(window: Window, afterWindow otherWindow: Window) -> Bool {
            guard let otherWindowIndex = windows.firstIndex(of: otherWindow) else {
                return false
            }

            windows.insert(window, at: otherWindowIndex)

            return true
        }

        func remove(window: Window) {
            for (_, lastMainWindow) in lastMainWindows where lastMainWindow?.id() == window.id() {
                if let currentFocusedSpace = Window.currentFocusedSpace() {
                    let secondWindow = activeWindowOnCurrentScreen(atIndex: 1)
                    lastMainWindows[currentFocusedSpace.id] = secondWindow
                }
            }

            guard let windowIndex = windows.firstIndex(where: { $0.id() == window.id() }) else {
                return
            }

            windows.remove(at: windowIndex)
        }

        @discardableResult func replace(window: Window, withWindow otherWindow: Window) -> Bool {
            if let currentFocusedSpace = Window.currentFocusedSpace(),
               let firstActiveWindow = activeWindowOnCurrentScreen(atIndex: 0) {
                if firstActiveWindow == window || firstActiveWindow == otherWindow {
                    lastMainWindows[currentFocusedSpace.id] = firstActiveWindow
                }
            }

            guard let otherWindowIndex = windows.firstIndex(of: otherWindow) else {
                windows.append(otherWindow)
                return false
            }

            let windowIndex = windows.firstIndex(of: window)
            windows[otherWindowIndex] = window

            if let windowIndex {
                windows.remove(at: windowIndex)
            }

            return true
        }

        @discardableResult func swap(window: Window, withWindow otherWindow: Window) -> Bool {
            if let currentFocusedSpace = Window.currentFocusedSpace(),
               let firstActiveWindow = activeWindowOnCurrentScreen(atIndex: 0) {
                if firstActiveWindow.id() == window.id() || firstActiveWindow.id() == otherWindow.id() {
                    lastMainWindows[currentFocusedSpace.id] = firstActiveWindow
                }
            }

            if windows.firstIndex(of: window) == nil {
                windows.append(window)
            }

            guard let windowIndex = windows.firstIndex(of: window), let otherWindowIndex = windows.firstIndex(of: otherWindow) else {
                return false
            }

            guard windowIndex != otherWindowIndex else {
                return false
            }

            windows[windowIndex] = otherWindow
            windows[otherWindowIndex] = window

            return true
        }

        // MARK: Window States

        func isWindowTracked(_ window: Window) -> Bool {
            return windowsByID[window.id()] != nil
        }

        func isWindowActive(_ window: Window) -> Bool {
            return window.isActive() && activeIDCache.contains(window.cgID())
        }

        func isWindowHidden(_ window: Window) -> Bool {
            return deactivatedPIDs.contains(window.pid())
        }

        func isWindowFloating(_ window: Window) -> Bool {
            return floatingMap[window.id()] ?? false
        }

        func setFloating(_ floating: Bool, forWindow window: Window) {
            floatingMap[window.id()] = floating
        }

        func activateApplication(withPID pid: pid_t) {
            deactivatedPIDs.remove(pid)
        }

        func deactivateApplication(withPID pid: pid_t) {
            deactivatedPIDs.insert(pid)
        }

        /// Refreshes the snapshot and returns it, so a caller that also needs the live set does not query twice.
        @discardableResult
        func regenerateActiveIDCache() -> Set<CGWindowID> {
            activeIDCache = onScreenWindowIDs()
            return activeIDCache
        }

        /// A live window-server query. Fetch once and test membership rather than calling `isOnScreen()` per window.
        func onScreenWindowIDs() -> Set<CGWindowID> {
            return Set(SIWindow.onScreenWindowIDs().map { $0.uint32Value })
        }

        // MARK: Window Sets

        func windowSet(forWindowsOnScreen screen: Screen) -> WindowSet<Window> {
            return windowSet(forWindows: windows(onScreen: screen))
        }

        func windowSet(forActiveWindowsOnScreen screen: Screen, on space: Space? = nil) -> WindowSet<Window> {
            if let space = space {
                return windowSet(forWindows: activeWindows(onScreen: screen, onSpace: space.id))
            } else {
                return windowSet(forWindows: activeWindows(onScreen: screen))
            }
        }

        func windowSet(forActiveWindowsOnSpace spaceID: CGSSpaceID, onScreen screen: Screen) -> WindowSet<Window> {
            return windowSet(forWindows: activeWindows(onScreen: screen, onSpace: spaceID))
        }

        func windowSet(forWindows windows: [Window]) -> WindowSet<Window> {
            // One focus query for the whole set instead of one per window.
            let focusedID = Window.currentlyFocused()?.id()
            let layoutWindows: [LayoutWindow<Window>] = windows.map {
                let id = $0.id()
                return LayoutWindow(id: id, frame: $0.frame(), isFocused: id == focusedID)
            }

            return WindowSet<Window>(
                windows: layoutWindows,
                isWindowWithIDActive: { [weak self] id -> Bool in
                    guard let window = self?.window(withID: id) else {
                        return false
                    }
                    return self?.isWindowActive(window) ?? false
                },
                isWindowWithIDFloating: { [weak self] windowID -> Bool in
                    guard let window = self?.window(withID: windowID) else {
                        return false
                    }
                    return self?.isWindowFloating(window) ?? false
                },
                windowForID: { [weak self] windowID -> Window? in
                    return self?.window(withID: windowID)
                }
            )
        }
    }
}
