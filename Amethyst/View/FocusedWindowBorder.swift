//
//  FocusedWindowBorder.swift
//  Amethyst
//

import Cocoa
import Silica

/// A click-through outline drawn just outside the focused window, ordered directly beneath it.
final class FocusedWindowBorder: NSWindow {
    /// Accessibility frames have a top-left origin on the primary display; AppKit frames have a bottom-left origin.
    static func appKitFrame(fromAccessibilityFrame frame: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        return CGRect(x: frame.minX, y: primaryScreenHeight - frame.maxY, width: frame.width, height: frame.height)
    }

    /// The overlay covers the window frame plus `width` on every side; the stroke is drawn in that outer band.
    static func borderFrame(around frame: CGRect, width: CGFloat) -> CGRect {
        return frame.insetBy(dx: -width, dy: -width)
    }

    /// Only windows Amethyst manages, on a user space, get an outline. Untracked windows (Spotlight, ignored apps)
    /// and fullscreen spaces do not.
    static func isEligible(tracked: Bool, managed: Bool, spaceType: CGSSpaceType?) -> Bool {
        return tracked && managed && spaceType == CGSSpaceTypeUser
    }
}
