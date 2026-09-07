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
        // Normal level on purpose: `order(.below, relativeTo:)` only interleaves windows within the same level band,
        // and the app windows we outline live at normal level.
        level = .normal
        // `.stationary` keeps the outline out of Mission Control and Exposé, like the desktop. It joins the focused
        // window's space explicitly in `show` rather than every space: with "Displays have separate Spaces" each display
        // has its own current space, and a `.canJoinAllSpaces` outline did not follow focus to a second display.
        collectionBehavior = [.stationary, .ignoresCycle]
        borderView.wantsLayer = true
        contentView = borderView
    }

    /// Positions the outline around `frame` (AppKit coordinates), moves it into `spaceID` and orders it just beneath
    /// the window with `target`. Main thread only, like every AppKit window call.
    func show(around frame: CGRect, below target: CGWindowID, in spaceID: CGSSpaceID?, color: NSColor, width: CGFloat) {
        dispatchPrecondition(condition: .onQueue(.main))
        borderView.color = color
        borderView.width = width
        setFrame(FocusedWindowBorder.borderFrame(around: frame, width: width), display: true)
        // A window can only be ordered relative to a window in the same space. A no-op when already there.
        if let spaceID = spaceID, windowNumber > 0 {
            CGSMoveWindowsToManagedSpace(CGSMainConnectionID(), [NSNumber(value: windowNumber)] as CFArray, spaceID)
        }
        // Foreign window numbers are accepted and this also orders the window on screen on its first call. If the
        // target sits at another level the call has no effect and the outline stays wherever it last was.
        order(.below, relativeTo: Int(target))
    }

    /// Main thread only.
    func hide() {
        dispatchPrecondition(condition: .onQueue(.main))
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
    var color: NSColor = NSColor(hexString: "#b38115") ?? .systemOrange
    var width: CGFloat = 4

    override func draw(_ dirtyRect: NSRect) {
        guard width > 0 else {
            return
        }
        // Inset by half the width so the whole stroke lands inside our bounds; the app window covers the inner half.
        // macOS window corners are about 10pt; keep the stroke concentric with them.
        let radius = 10 + width / 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: width / 2, dy: width / 2), xRadius: radius, yRadius: radius)
        path.lineWidth = width
        color.setStroke()
        path.stroke()
    }
}
