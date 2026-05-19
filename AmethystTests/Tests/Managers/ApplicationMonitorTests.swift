//
//  ApplicationMonitorTests.swift
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

class ApplicationMonitorTests: QuickSpec {
    override func spec() {
        var monitor: ApplicationMonitor<MockApplication>!

        beforeEach {
            monitor = ApplicationMonitor<MockApplication>()
        }

        describe("ApplicationMonitor") {
            it("testAddApplication_storesApplication") {
                let app = MockApplication(pid: 123)
                monitor.add(application: app)
                let retrieved = monitor.application(withPID: 123)
                expect(retrieved).toNot(beNil())
                expect(retrieved?.pid()).to(equal(123))
            }

            it("testRemoveApplication_removesFromTracking") {
                let app = MockApplication(pid: 456)
                monitor.add(application: app)
                monitor.remove(application: app)
                let retrieved = monitor.application(withPID: 456)
                expect(retrieved).to(beNil())
            }

            it("testApplicationWithPID_returnsNilForUnknownPID") {
                let retrieved = monitor.application(withPID: 999)
                expect(retrieved).to(beNil())
            }
        }
    }
}
