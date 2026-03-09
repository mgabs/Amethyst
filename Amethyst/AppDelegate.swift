//
//  AppDelegate.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 5/8/16.
//  Copyright © 2016 Ian Ynda-Hummel. All rights reserved.
//

import Cocoa
import CoreServices
import Foundation
import LoginServiceKit
import RxCocoa
import RxSwift
import Silica
import Sparkle
import SwiftyBeaver

class AppDelegate: NSObject, NSApplicationDelegate {
    static let windowManagerEncodingKey = "EncodedWindowManager"

    fileprivate var windowManager: WindowManager<SIApplication>?
    private var hotKeyManager: HotKeyManager<SIApplication>?

    fileprivate var statusItem: NSStatusItem?
    @IBOutlet var statusItemMenu: NSMenu?
    @IBOutlet var versionMenuItem: NSMenuItem?
    @IBOutlet var startAtLoginMenuItem: NSMenuItem?
    @IBOutlet var toggleGlobalTilingMenuItem: NSMenuItem?
    @IBOutlet var layoutsMenuItem: NSMenuItem?

    private var spaceIndicatorManager: SpaceIndicatorManager?
    private var showSpaceIndicatorMenuItem: NSMenuItem?

    private var isFirstLaunch = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
            log.addDestination(ConsoleDestination())
        #endif

        if CommandLine.arguments.contains("--log") {
            let destination = ConsoleDestination()
            destination.useNSLog = true
            log.addDestination(destination)
        }

        log.info("Logging is enabled")
        log.debug("Debug logging is enabled")

        UserConfiguration.shared.delegate = self
        UserConfiguration.shared.load()

        #if RELEASE
            let appcastURLString = { () -> String? in
                if UserConfiguration.shared.useCanaryBuild() {
                    return Bundle.main.infoDictionary?["SUCanaryFeedURL"] as? String
                } else {
                    return Bundle.main.infoDictionary?["SUFeedURL"] as? String
                }
            }()!

            SUUpdater.shared().feedURL = URL(string: appcastURLString)
        #endif

        if let encodedWindowManager = UserDefaults.standard.data(forKey: AppDelegate.windowManagerEncodingKey), UserConfiguration.shared.restoreLayoutsOnLaunch() {
            let decoder = JSONDecoder()
            windowManager = try? decoder.decode(WindowManager<SIApplication>.self, from: encodedWindowManager)
        }

        windowManager = windowManager ?? WindowManager(userConfiguration: UserConfiguration.shared)
        hotKeyManager = HotKeyManager(userConfiguration: UserConfiguration.shared)

        hotKeyManager?.setUpWithWindowManager(windowManager!, configuration: UserConfiguration.shared, appDelegate: self)

        setupSpaceIndicator()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let statusItemImage = NSImage(named: "icon-statusitem")
        statusItemImage?.isTemplate = true

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.image = statusItemImage
        statusItem?.menu = statusItemMenu
        statusItem?.highlightMode = true

        let hideMenuBarIcon: Bool = UserConfiguration.shared.hideMenuBarIcon()
        statusItem?.isVisible = !hideMenuBarIcon

        versionMenuItem?.title = "Version \(shortVersion) (\(version))"
        toggleGlobalTilingMenuItem?.title = "Disable"

        startAtLoginMenuItem?.state = (LoginServiceKit.isExistLoginItems(at: Bundle.main.bundlePath) ? .on : .off)

        statusItemMenu?.delegate = self
    }

    private func setupSpaceIndicator() {
        guard let statusItem = statusItem, let menu = statusItemMenu else { return }

        spaceIndicatorManager = SpaceIndicatorManager(statusItem: statusItem, userConfiguration: UserConfiguration.shared) { [weak self] in
            return self?.windowManager?.focusedScreenManager()?.screen?.screenID()
        }

        let spaceIndicatorMenuItem = NSMenuItem(title: "Space Indicator", action: nil, keyEquivalent: "")
        let spaceIndicatorSubmenu = NSMenu()

        let showItem = NSMenuItem(title: "Show Space Number", action: #selector(toggleSpaceIndicator(_:)), keyEquivalent: "")
        showItem.target = self
        showItem.state = UserConfiguration.shared.showSpaceIndicator() ? .on : .off
        spaceIndicatorSubmenu.addItem(showItem)
        showSpaceIndicatorMenuItem = showItem

        spaceIndicatorSubmenu.addItem(NSMenuItem.separator())

        let singleItem = NSMenuItem(title: "Single Icon", action: #selector(setSpaceIndicatorStyle(_:)), keyEquivalent: "")
        singleItem.target = self
        singleItem.tag = SpaceIndicatorStyle.single.rawValue
        singleItem.state = UserConfiguration.shared.spaceIndicatorStyle() == .single ? .on : .off
        spaceIndicatorSubmenu.addItem(singleItem)

        let perMonitorItem = NSMenuItem(title: "One Icon Per Monitor", action: #selector(setSpaceIndicatorStyle(_:)), keyEquivalent: "")
        perMonitorItem.target = self
        perMonitorItem.tag = SpaceIndicatorStyle.perMonitor.rawValue
        perMonitorItem.state = UserConfiguration.shared.spaceIndicatorStyle() == .perMonitor ? .on : .off
        spaceIndicatorSubmenu.addItem(perMonitorItem)

        let allSpacesItem = NSMenuItem(title: "One Icon Per Space", action: #selector(setSpaceIndicatorStyle(_:)), keyEquivalent: "")
        allSpacesItem.target = self
        allSpacesItem.tag = SpaceIndicatorStyle.allSpaces.rawValue
        allSpacesItem.state = UserConfiguration.shared.spaceIndicatorStyle() == .allSpaces ? .on : .off
        spaceIndicatorSubmenu.addItem(allSpacesItem)

        spaceIndicatorSubmenu.addItem(NSMenuItem.separator())

        let colorStyleItem = NSMenuItem(title: "Color Style", action: nil, keyEquivalent: "")
        let colorStyleSubmenu = NSMenu()

        let borderedItem = NSMenuItem(title: "Bordered", action: #selector(setSpaceIndicatorColorStyle(_:)), keyEquivalent: "")
        borderedItem.target = self
        borderedItem.tag = SpaceIndicatorColorStyle.bordered.rawValue
        borderedItem.state = UserConfiguration.shared.spaceIndicatorColorStyle() == .bordered ? .on : .off
        colorStyleSubmenu.addItem(borderedItem)
let solidItem = NSMenuItem(title: "Solid", action: #selector(setSpaceIndicatorColorStyle(_:)), keyEquivalent: "")
solidItem.target = self
solidItem.tag = SpaceIndicatorColorStyle.solid.rawValue
solidItem.state = UserConfiguration.shared.spaceIndicatorColorStyle() == .solid ? .on : .off
colorStyleSubmenu.addItem(solidItem)

let solidInvertedItem = NSMenuItem(title: "Solid Inverted", action: #selector(setSpaceIndicatorColorStyle(_:)), keyEquivalent: "")
solidInvertedItem.target = self
solidInvertedItem.tag = SpaceIndicatorColorStyle.solidInverted.rawValue
solidInvertedItem.state = UserConfiguration.shared.spaceIndicatorColorStyle() == .solidInverted ? .on : .off
colorStyleSubmenu.addItem(solidInvertedItem)

colorStyleItem.submenu = colorStyleSubmenu
spaceIndicatorSubmenu.addItem(colorStyleItem)

spaceIndicatorMenuItem.submenu = spaceIndicatorSubmenu

        // Insert before "Quit"
        menu.insertItem(spaceIndicatorMenuItem, at: menu.numberOfItems - 1)

        // Observe space changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Observe screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(spaceDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Observe focus changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        DispatchQueue.main.async { [weak self] in
            self?.updateSpaceIndicator()
        }
    }

    @objc private func setSpaceIndicatorStyle(_ sender: NSMenuItem) {
        guard let style = SpaceIndicatorStyle(rawValue: sender.tag) else { return }
        UserConfiguration.shared.setSpaceIndicatorStyle(style)

        // Update menu item states
        if let submenu = sender.menu {
            for item in submenu.items {
                if item.action == #selector(setSpaceIndicatorStyle(_:)) {
                    item.state = (item.tag == sender.tag) ? .on : .off
                }
            }
        }

        updateSpaceIndicator()
    }

    @objc private func setSpaceIndicatorColorStyle(_ sender: NSMenuItem) {
        guard let style = SpaceIndicatorColorStyle(rawValue: sender.tag) else { return }
        UserConfiguration.shared.setSpaceIndicatorColorStyle(style)

        // Update menu item states
        if let submenu = sender.menu {
            for item in submenu.items {
                if item.action == #selector(setSpaceIndicatorColorStyle(_:)) {
                    item.state = (item.tag == sender.tag) ? .on : .off
                }
            }
        }

        updateSpaceIndicator()
    }
    @objc private func spaceDidChange(_ notification: Notification) {
        // during rapid space switching
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateSpaceIndicator()
        }
    }

    @objc private func toggleSpaceIndicator(_ sender: NSMenuItem) {
        let newValue = !UserConfiguration.shared.showSpaceIndicator()
        UserConfiguration.shared.setShowSpaceIndicator(newValue)
        sender.state = newValue ? .on : .off
        updateSpaceIndicator()
    }

    private func updateSpaceIndicator() {
        if UserConfiguration.shared.showSpaceIndicator() {
            spaceIndicatorManager?.update()
        } else {
            // Restore default icon
            configurationGlobalTilingDidChange(UserConfiguration.shared)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        let hasAccessibilityPermissions = UserConfiguration.shared.confirmAccessibilityPermissions()
        if UserConfiguration.shared.hasAccessibilityPermissions != hasAccessibilityPermissions {
            UserConfiguration.shared.hasAccessibilityPermissions = hasAccessibilityPermissions
        }

        guard !isFirstLaunch else {
            isFirstLaunch = false
            return
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard let windowManager = windowManager else {
            return
        }

        do {
            let encoder = JSONEncoder()
            let encodedWindowManager = try encoder.encode(windowManager)
            UserDefaults.standard.set(encodedWindowManager, forKey: AppDelegate.windowManagerEncodingKey)
        } catch {
            log.error("Failed to encode window manager: \(error)")
        }
    }

    @IBAction func toggleStartAtLogin(_ sender: AnyObject) {
        if startAtLoginMenuItem?.state == .off {
            LoginServiceKit.addLoginItems(at: Bundle.main.bundlePath)
        } else {
            LoginServiceKit.removeLoginItems(at: Bundle.main.bundlePath)
        }
        startAtLoginMenuItem?.state = (LoginServiceKit.isExistLoginItems(at: Bundle.main.bundlePath) ? .on : .off)
    }

    @IBAction func toggleGlobalTiling(_ sender: AnyObject) {
        UserConfiguration.shared.tilingEnabled = !UserConfiguration.shared.tilingEnabled
        windowManager?.markAllScreensForReflow()
    }

    @IBAction func resetLayouts(_ sender: AnyObject) {
        UserDefaults.standard.removeObject(forKey: AppDelegate.windowManagerEncodingKey)
        windowManager?.reset()
    }

    @IBAction func relaunch(_ sender: AnyObject) {
        AppManager.relaunch()
    }

    @IBAction func checkForUpdates(_ sender: AnyObject) {
        #if RELEASE
            SUUpdater.shared().checkForUpdates(sender)
        #endif
    }

    private func populateLayoutsMenu() {
        guard let layoutsMenuItem = layoutsMenuItem,
              let submenu = layoutsMenuItem.submenu else {
            return
        }

        // Clear existing items
        submenu.removeAllItems()

        // Get screen manager: try focused screen first, then screen under mouse cursor
        let screenManager: ScreenManager<WindowManager<SIApplication>>? = {
            if let focused = windowManager?.focusedScreenManager() {
                return focused
            }
            // Fallback to screen containing mouse cursor (useful when clicking menu bar)
            let mouseLocation = NSEvent.mouseLocation
            if let nsScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
                let amScreen = AMScreen(screen: nsScreen)
                return windowManager?.screenManager(for: amScreen)
            }
            return nil
        }()

        guard let screenManager = screenManager else {
            let errorItem = NSMenuItem(title: "Unable to determine current screen", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            submenu.addItem(errorItem)
            return
        }

        // Get layouts from the screen manager (not from global config)
        let layouts = screenManager.layoutsInfo

        // Check if no layouts are available and return early
        if layouts.isEmpty {
            let noLayoutsItem = NSMenuItem(title: "No layouts enabled", action: nil, keyEquivalent: "")
            noLayoutsItem.isEnabled = false
            submenu.addItem(noLayoutsItem)
            return
        }

        // Add menu items for each layout in the screen manager
        for layoutInfo in layouts {
            let menuItem = NSMenuItem(title: layoutInfo.name, action: #selector(selectLayout(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = layoutInfo.key
            menuItem.state = layoutInfo.isSelected ? .on : .off

            submenu.addItem(menuItem)
        }
    }

    @IBAction func selectLayout(_ sender: NSMenuItem) {
        guard let layoutKey = sender.representedObject as? String,
              let windowManager = windowManager,
              let screenManager = windowManager.focusedScreenManager() else {
            return
        }

        screenManager.selectLayout(layoutKey)
        // Menu will be refreshed automatically when next opened via NSMenuDelegate
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh layouts menu when main status item menu is about to open
        if menu == statusItemMenu {
            populateLayoutsMenu()
        }
    }
}

extension AppDelegate: UserConfigurationDelegate {
    func configurationGlobalTilingDidChange(_ userConfiguration: UserConfiguration) {
        var statusItemImage: NSImage?
        if UserConfiguration.shared.tilingEnabled == true {
            statusItemImage = NSImage(named: "icon-statusitem")
            toggleGlobalTilingMenuItem?.title = "Disable Tiling"
        } else {
            statusItemImage = NSImage(named: "icon-statusitem-disabled")
            toggleGlobalTilingMenuItem?.title = "Enable Tiling"
        }

        if UserConfiguration.shared.showSpaceIndicator() {
            spaceIndicatorManager?.update()
            return
        }

        statusItemImage?.isTemplate = true
        statusItem?.image = statusItemImage
    }

    func configurationAccessibilityPermissionsDidChange(_ userConfiguration: UserConfiguration) {
        windowManager?.reevaluateWindows()
    }
}
class SpaceIndicatorManager {
    private let statusItem: NSStatusItem
    private let userConfiguration: UserConfiguration
    private let focusedScreenProvider: () -> String?
    private let size = CGSize(width: 16, height: 16)

    init(statusItem: NSStatusItem, userConfiguration: UserConfiguration, focusedScreenProvider: @escaping () -> String?) {
        self.statusItem = statusItem
        self.userConfiguration = userConfiguration
        self.focusedScreenProvider = focusedScreenProvider
    }

    func update() {
        guard userConfiguration.showSpaceIndicator() else {
            return
        }

        let style = userConfiguration.spaceIndicatorStyle()
        let image: NSImage

        switch style {
        case .single:
            let text = getCurrentSpaceNumber()
            image = createSpaceImage(text: text, isFocused: true)
        case .perMonitor:
            image = createPerMonitorImage()
        case .allSpaces:
            image = createAllSpacesImage()
        }

        statusItem.button?.image = image
    }

    private func getCurrentSpaceNumber() -> String {
        guard let info = getSpaceInfo() else { return "?" }
        return info.currentSpace
    }

    private func createPerMonitorImage() -> NSImage {
        guard let info = getSpaceInfo() else { return createSpaceImage(text: "?", isFocused: true) }
        let images = info.activeSpaces.map { createSpaceImage(text: $0.text, isActive: true, isFocused: $0.isFocused) }
        return combine(images: images)
    }

    private func createAllSpacesImage() -> NSImage {
        guard let info = getSpaceInfo() else { return createSpaceImage(text: "?", isFocused: true) }
        let images = info.allSpaces.map { createSpaceImage(text: $0.text, isActive: $0.isActive, isFocused: $0.isFocused) }
        return combine(images: images)
    }

    private struct SpaceInfo {
        let currentSpace: String
        let activeSpaces: [(text: String, isFocused: Bool)]
        let allSpaces: [(text: String, isActive: Bool, isFocused: Bool)]
    }

    private func getSpaceInfo() -> SpaceInfo? {
        guard let cfScreenDescriptions = CGSCopyManagedDisplaySpaces(CGSMainConnectionID())?.takeRetainedValue() else {
            return nil
        }
        guard let screenDescriptions = cfScreenDescriptions as NSArray as? [[String: AnyObject]] else {
            return nil
        }

        let mainScreenID = focusedScreenProvider()
        var currentSpaceNumber = "?"
        var activeSpaces: [(text: String, isFocused: Bool)] = []
        var allSpaces: [(text: String, isActive: Bool, isFocused: Bool)] = []

        var counter = 1
        for screenDescription in screenDescriptions {
            guard let currentSpace = screenDescription["Current Space"] as? [String: Any],
                  let spaces = screenDescription["Spaces"] as? [[String: Any]] else {
                continue
            }

            let screenID = screenDescription["Display Identifier"] as? String
            let isFocusedScreen = (screenID == mainScreenID)
            let activeSpaceUUID = currentSpace["uuid"] as? String

            for space in spaces {
                let isFullscreen = space["TileLayoutManager"] != nil
                let text = isFullscreen ? "F" : "\(counter)"
                let isActive = space["uuid"] as? String == activeSpaceUUID
                let isFocused = isActive && isFocusedScreen

                if isActive {
                    activeSpaces.append((text: text, isFocused: isFocused))
                    if isFocusedScreen {
                        currentSpaceNumber = text
                    }
                }

                allSpaces.append((text: text, isActive: isActive, isFocused: isFocused))

                if !isFullscreen {
                    counter += 1
                }
            }
        }

        return SpaceInfo(currentSpace: currentSpaceNumber, activeSpaces: activeSpaces, allSpaces: allSpaces)
    }

    private func createSpaceImage(text: String, isActive: Bool = true, isFocused: Bool = false) -> NSImage {
        let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let image = NSImage(size: size)

        let alpha: CGFloat = isActive ? 1.0 : 0.3
        let colorStyle = userConfiguration.spaceIndicatorColorStyle()

        image.lockFocus()

        let font = NSFont.boldSystemFont(ofSize: 11)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        if isFocused {
            attributes[.underlineStyle] = NSUnderlineStyle.thick.rawValue
        }

        switch colorStyle {
        case .bordered:
            let color = NSColor.labelColor.withAlphaComponent(alpha)
            attributes[.foregroundColor] = color

            let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 2, yRadius: 2)
            color.set()
            path.lineWidth = 1.0
            path.stroke()

            let stringSize = text.size(withAttributes: attributes)
            let stringRect = NSRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.size.height - stringSize.height) / 2.0,
                width: rect.size.width,
                height: stringSize.height
            )
            text.draw(in: stringRect, withAttributes: attributes)

        case .solid:
            let color = NSColor.labelColor.withAlphaComponent(alpha)
            let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            color.set()
            path.fill()

            attributes[.foregroundColor] = NSColor.controlBackgroundColor // Use a contrasting color for text

            let stringSize = text.size(withAttributes: attributes)
            let stringRect = NSRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.size.height - stringSize.height) / 2.0,
                width: rect.size.width,
                height: stringSize.height
            )
            text.draw(in: stringRect, withAttributes: attributes)

        case .solidInverted:
            let bgColor = NSColor.black.withAlphaComponent(alpha)
            let textColor = NSColor.white.withAlphaComponent(alpha)

            let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            bgColor.set()
            path.fill()

            attributes[.foregroundColor] = textColor

            let stringSize = text.size(withAttributes: attributes)
            let stringRect = NSRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.size.height - stringSize.height) / 2.0,
                width: rect.size.width,
                height: stringSize.height
            )
            text.draw(in: stringRect, withAttributes: attributes)
        }

        image.unlockFocus()
        image.isTemplate = (colorStyle != .solidInverted)
        return image
    }

    private func combine(images: [NSImage]) -> NSImage {
        let spacing: CGFloat = 2.0
        let totalWidth = images.reduce(0) { $0 + $1.size.width } + CGFloat(images.count - 1) * spacing
        let combinedSize = CGSize(width: totalWidth, height: size.height)
        let combinedImage = NSImage(size: combinedSize)

        combinedImage.lockFocus()
        var currentX: CGFloat = 0
        for image in images {
            image.draw(at: NSPoint(x: currentX, y: 0), from: .zero, operation: .sourceOver, fraction: 1.0)
            currentX += image.size.width + spacing
        }
        combinedImage.unlockFocus()

        combinedImage.isTemplate = images.allSatisfy { $0.isTemplate }
        return combinedImage
    }
}
