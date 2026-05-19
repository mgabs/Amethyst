//
//  WindowTrackerTests.swift
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

private final class MockApplication: ApplicationType {
    typealias Window = TestWindow

    static func == (lhs: MockApplication, rhs: MockApplication) -> Bool {
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
    func dropWindowsCache() {}
    func observe(notification: String, handler: @escaping SIAXNotificationHandler) -> AXError { return .success }
    func observe(notification: String, window: TestWindow, handler: @escaping SIAXNotificationHandler) -> AXError { return .success }
    func unobserve(notification: String) {}
    func unobserve(notification: String, window: TestWindow) {}
}

class WindowTrackerTests: QuickSpec {
    override func spec() {
        var tracker: WindowTracker<MockApplication>!

        beforeEach {
            tracker = WindowTracker<MockApplication>()
        }

        describe("WindowTracker") {
            it("testAddWindow_storesWindow") {
                let app = MockApplication(pid: 1)
                let window = TestWindow(element: nil)!
                tracker.add(window: window, application: app)
                expect(tracker.isWindowTracked(window)).to(beTrue())
            }

            it("testRemoveWindow_removesFromTracking") {
                let app = MockApplication(pid: 2)
                let window = TestWindow(element: nil)!
                tracker.add(window: window, application: app)
                tracker.remove(window: window)
                expect(tracker.isWindowTracked(window)).to(beFalse())
            }

            it("testIsWindowTracked_returnsFalseForUnknownWindow") {
                let unknownWindow = TestWindow(element: nil)!
                expect(tracker.isWindowTracked(unknownWindow)).to(beFalse())
            }

            it("testWindowsForApplication_returnsOnlyThatAppWindows") {
                let app1 = MockApplication(pid: 10)
                let app2 = MockApplication(pid: 20)
                let window1 = TestWindow(element: nil)!
                let window2 = TestWindow(element: nil)!
                let window3 = TestWindow(element: nil)!
                tracker.add(window: window1, application: app1)
                tracker.add(window: window2, application: app1)
                tracker.add(window: window3, application: app2)
                let app1Windows = tracker.windows(forApplicationWithPID: 10)
                expect(app1Windows.count).to(equal(2))
                let app2Windows = tracker.windows(forApplicationWithPID: 20)
                expect(app2Windows.count).to(equal(1))
            }
        }
    }
}
