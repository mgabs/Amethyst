//
//  FocusedWindowBorder.swift
//  Amethyst
//

import Cocoa
import Silica

/// A click-through outline drawn just outside the focused window, ordered directly beneath it.
final class FocusedWindowBorder: NSWindow {
    private let borderView = BorderView()

    init() {
        super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        contentView = borderView
    }

    /// Positions the outline around `frame` (AppKit coordinates) and orders it just beneath the window with `windowNumber`.
    func show(around frame: CGRect, below windowNumber: CGWindowID, color: NSColor, width: CGFloat) {
        borderView.color = color
        borderView.width = width
        setFrame(FocusedWindowBorder.borderFrame(around: frame, width: width), display: false)
        borderView.needsDisplay = true
        // Cross-process window numbers are accepted here; if the call has no effect the outline stays at its own level.
        order(.below, relativeTo: Int(windowNumber))
    }

    func hide() {
        orderOut(nil)
    }

    // MARK: Geometry

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

/// Strokes a rounded rectangle in the outer band of its bounds.
private final class BorderView: NSView {
    var color: NSColor = .systemGreen
    var width: CGFloat = 4

    override func draw(_ dirtyRect: NSRect) {
        guard width > 0 else {
            return
        }
        // Inset by half the width so the whole stroke lands inside our bounds; the app window covers the inner half.
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: width / 2, dy: width / 2), xRadius: width, yRadius: width)
        path.lineWidth = width
        color.setStroke()
        path.stroke()
    }
}
