//
//  CGInfo.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 3/29/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Foundation
import Silica

/// Windows info as taken from the underlying system.
struct CGWindowsInfo<Window: WindowType> {
    /// An array of dictionaries of window information
    let descriptions: [[String: AnyObject]]

    /**
     - Parameters:
     - options: Any options for getting info.
     - windowID: ID of window to find windows relative to. 0 gets all windows.
     */
    init?(options: CGWindowListOption, windowID: CGWindowID) {
        guard let cfWindowDescriptions = CGWindowListCopyWindowInfo(options, windowID) else {
            return nil
        }

        guard let windowDescriptions = cfWindowDescriptions as? [[String: AnyObject]] else {
            return nil
        }

        self.descriptions = windowDescriptions
    }

    /**
     - Returns:
     The set of windows that are currently active.
     */
    func activeIDs() -> Set<CGWindowID> {
        var ids: Set<CGWindowID> = Set()

        for windowDescription in descriptions {
            guard let windowID = windowDescription[kCGWindowNumber as String] as? NSNumber else {
                continue
            }

            ids.insert(CGWindowID(windowID.uint64Value))
        }

        return ids
    }

    static func windowIDsArray(_ window: Window) -> NSArray {
        return [NSNumber(value: window.cgID() as UInt32)] as NSArray
    }

    static func windowSpace(_ window: Window) -> Int? {
        let windowIDsArray = CGWindowsInfo.windowIDsArray(window)

        guard let cfSpaces = CGSCopySpacesForWindows(CGSMainConnectionID(), kCGSAllSpacesMask, windowIDsArray)?.takeRetainedValue() else {
            return nil
        }

        guard let spaces = cfSpaces as NSArray as? [NSNumber] else {
            return nil
        }

        guard !spaces.isEmpty else {
            return nil
        }

        return spaces.first?.intValue
    }
}
