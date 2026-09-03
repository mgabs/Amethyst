//
//  FocusManagerTests.swift
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

class FocusManagerTests: QuickSpec {
    override func spec() {
        var focusManager: FocusManager<MockFocusApplication>!

        beforeEach {
            focusManager = FocusManager<MockFocusApplication>()
        }

        describe("FocusManager") {
            it("testLastFocusedWindow_returnsNilInitially") {
                expect(focusManager.lastFocusedWindow).to(beNil())
            }

            it("testSetFocusedWindow_updatesCurrent") {
                let window = TestWindow(element: nil)!
                focusManager.setFocused(window: window)
                expect(focusManager.lastFocusedWindow).to(equal(window))
            }

            it("testClearFocus_removesLastFocused") {
                let window = TestWindow(element: nil)!
                focusManager.setFocused(window: window)
                focusManager.clearFocus()
                expect(focusManager.lastFocusedWindow).to(beNil())
            }
        }
    }
}

private final class MockFocusApplication: ApplicationType {
    typealias Window = TestWindow

    static func == (lhs: MockFocusApplication, rhs: MockFocusApplication) -> Bool {
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
