//
//  WindowsInformation.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 5/15/16.
//  Copyright © 2016 Ian Ynda-Hummel. All rights reserved.
//

import Foundation
import Silica

/// Answers "which of these windows is under this point" using the window server's own front-to-back order and CoreGraphics window IDs.
enum WindowsInformation<Window: WindowType> {
    /// The front-most window in `windows` whose on-screen bounds contain `point`.
    static func topWindowForScreenAtPoint(_ point: CGPoint, withWindows windows: [Window]) -> Window? {
        return windowsAtPoint(point, in: windows).first
    }

    /// The front-most window in `windows` under `point` that is not `ignoreWindow`.
    static func alternateWindowForScreenAtPoint(_ point: CGPoint, withWindows windows: [Window], butNot ignoreWindow: Window?) -> Window? {
        return windowsAtPoint(point, in: windows).first { $0 != ignoreWindow }
    }

    /// Windows in `windows` under `point`, front to back. One window-list copy per call.
    private static func windowsAtPoint(_ point: CGPoint, in windows: [Window]) -> [Window] {
        let windowsByID = Dictionary(windows.map { ($0.cgID(), $0) }, uniquingKeysWith: { first, _ in first })
        return SIWindow.onScreenWindowIDs(at: point).compactMap { windowsByID[$0.uint32Value] }
    }
}
