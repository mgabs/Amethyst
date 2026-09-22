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

    private(set) var targetWindowID: CGWindowID?

    /// Positions the outline around `frame` (AppKit coordinates), moves it into `spaceID` and orders it just beneath
    /// the window with `target`. Main thread only, like every AppKit window call.
    func show(around frame: CGRect, below target: CGWindowID, in spaceID: CGSSpaceID?, color: NSColor, width: CGFloat) {
        dispatchPrecondition(condition: .onQueue(.main))
        targetWindowID = target
        borderView.update(color: color, width: width)
        let newFrame = FocusedWindowBorder.borderFrame(around: frame, width: width)
        if self.frame != newFrame {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            setFrame(newFrame, display: true)
            CATransaction.commit()
        }
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
        targetWindowID = nil
        orderOut(nil)
    }

    /// Hides the outline immediately if it is currently displayed around the window with `windowID`.
    func hideIfTargetMatches(_ windowID: CGWindowID) {
        dispatchPrecondition(condition: .onQueue(.main))
        if targetWindowID == windowID {
            hide()
        }
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

/// Layer-backed view displaying the focused outline via CALayer border properties.
private final class BorderView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(color: NSColor, width: CGFloat) {
        guard let layer = layer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        layer.cornerRadius = 10 + width / 2
        CATransaction.commit()
    }
}
