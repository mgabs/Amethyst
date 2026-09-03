//
//  WindowManagementIntegrationTests.swift
//  AmethystTests
//
//  Created by Mohammed Metawea on 2026-05-19.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import AppKit
import Foundation
import Nimble
import Quick
import Silica

// MARK: - Shared Mock (Integration scope)

private final class IntegrationMockApplication: ApplicationType {
    typealias Window = TestWindow

    static func == (lhs: IntegrationMockApplication, rhs: IntegrationMockApplication) -> Bool {
        return lhs.mockPID == rhs.mockPID
    }

    let mockPID: pid_t

    required init(runningApplication: NSRunningApplication) {
        mockPID = runningApplication.processIdentifier
    }

    init(pid: pid_t) {
        mockPID = pid
    }

    func title() -> String? { return nil }
    func windows() -> [TestWindow] { return [] }
    func pid() -> pid_t { return mockPID }
    func defaultFloatForWindow(_ window: TestWindow) -> Reliable<DefaultFloat> { return .reliable(.floating) }
    func observe(notification: String, handler: @escaping SIAXNotificationHandler) -> AXError { return .success }
    func observe(notification: String, window: TestWindow, handler: @escaping SIAXNotificationHandler) -> AXError { return .success }
    func unobserve(notification: String) {}
    func unobserve(notification: String, window: TestWindow) {}
}

// MARK: - Integration Tests

class WindowManagementIntegrationTests: QuickSpec {
    override class func spec() {
        var applicationMonitor: ApplicationMonitor<IntegrationMockApplication>!
        var windowTracker: WindowTracker<IntegrationMockApplication>!
        var focusManager: FocusManager<IntegrationMockApplication>!

        beforeEach {
            applicationMonitor = ApplicationMonitor<IntegrationMockApplication>()
            windowTracker = WindowTracker<IntegrationMockApplication>()
            focusManager = FocusManager<IntegrationMockApplication>()
        }

        describe("WindowManagementIntegration") {
            it("testApplicationLaunchFlow_tracksWindowsCorrectly") {
                // Simulate app launch: register in ApplicationMonitor
                let app = IntegrationMockApplication(pid: 100)
                applicationMonitor.add(application: app)

                // Simulate window creation: register in WindowTracker
                let window = TestWindow(element: nil)!
                windowTracker.add(window: window, application: app)

                // Focus the window via FocusManager
                focusManager.setFocused(window: window)

                // Verify consistent state across all three managers
                expect(applicationMonitor.application(withPID: 100)).toNot(beNil())
                expect(applicationMonitor.application(withPID: 100)?.pid()).to(equal(100))
                expect(windowTracker.isWindowTracked(window)).to(beTrue())
                expect(windowTracker.windows(forApplicationWithPID: 100).count).to(equal(1))
                expect(focusManager.lastFocusedWindow).to(equal(window))
                expect(focusManager.isFocused(window: window)).to(beTrue())
            }

            it("testFocusTransitionFlow_maintainsConsistentState") {
                // Set up two apps and two windows
                let app1 = IntegrationMockApplication(pid: 200)
                let app2 = IntegrationMockApplication(pid: 201)
                applicationMonitor.add(application: app1)
                applicationMonitor.add(application: app2)

                let window1 = TestWindow(element: nil)!
                let window2 = TestWindow(element: nil)!
                windowTracker.add(window: window1, application: app1)
                windowTracker.add(window: window2, application: app2)

                // Focus window1 first
                focusManager.setFocused(window: window1)
                expect(focusManager.lastFocusedWindow).to(equal(window1))
                expect(focusManager.isFocused(window: window1)).to(beTrue())
                expect(focusManager.isFocused(window: window2)).to(beFalse())

                // Transition focus to window2
                focusManager.setFocused(window: window2)
                expect(focusManager.lastFocusedWindow).to(equal(window2))
                expect(focusManager.isFocused(window: window2)).to(beTrue())
                expect(focusManager.isFocused(window: window1)).to(beFalse())

                // Both windows still tracked in WindowTracker
                expect(windowTracker.isWindowTracked(window1)).to(beTrue())
                expect(windowTracker.isWindowTracked(window2)).to(beTrue())

                // Both apps still tracked in ApplicationMonitor
                expect(applicationMonitor.application(withPID: 200)).toNot(beNil())
                expect(applicationMonitor.application(withPID: 201)).toNot(beNil())

                // Window removal clears tracker but focus manager retains last reference
                windowTracker.remove(window: window1)
                expect(windowTracker.isWindowTracked(window1)).to(beFalse())
                expect(windowTracker.isWindowTracked(window2)).to(beTrue())

                // Focus state is still consistent for window2
                expect(focusManager.lastFocusedWindow).to(equal(window2))
            }
        }
    }
}
