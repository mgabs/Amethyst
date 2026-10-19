//
//  WindowTransitionCoordinatorTests.swift
//  AmethystTests
//
//  Created by Ian Ynda-Hummel on 10/19/26.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import AppKit
import Foundation
import Nimble
import Quick
import Silica

private final class MockTransitionApplication: ApplicationType {
    typealias Window = TestWindow

    static func == (lhs: MockTransitionApplication, rhs: MockTransitionApplication) -> Bool {
        return lhs.mockPID == rhs.mockPID
    }

    let mockPID: pid_t

    required init(runningApplication: NSRunningApplication) {
        mockPID = runningApplication.processIdentifier
    }

    init(pid: pid_t = 1234) {
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
    func dropWindowsCache() {}
}

private final class MockTransitionTarget: WindowTransitionTarget {
    typealias Application = MockTransitionApplication

    var executedTransitions: [WindowTransition<TestWindow>] = []
    var floatingWindowIDs: Set<String> = []
    var screens: [TestScreen] = []

    func executeTransition(_ transition: WindowTransition<TestWindow>) {
        executedTransitions.append(transition)
    }

    func isWindowFloating(_ window: TestWindow) -> Bool {
        return floatingWindowIDs.contains(window.id())
    }

    func currentLayout() -> Layout<TestWindow>? {
        return nil
    }

    func screen(at index: Int) -> TestScreen? {
        guard index >= 0, index < screens.count else { return nil }
        return screens[index]
    }

    func activeWindows(on screen: TestScreen) -> [TestWindow] {
        return []
    }

    func nextScreenIndexClockwise(from screen: TestScreen) -> Int {
        guard let index = screens.firstIndex(where: { $0.screenID() == screen.screenID() }) else { return 0 }
        return (index + 1) % screens.count
    }

    func nextScreenIndexCounterClockwise(from screen: TestScreen) -> Int {
        guard let index = screens.firstIndex(where: { $0.screenID() == screen.screenID() }) else { return 0 }
        return (index - 1 + screens.count) % screens.count
    }

    func lastMainWindowForCurrentSpace() -> TestWindow? {
        return nil
    }
}

final class WindowTransitionCoordinatorTests: QuickSpec {
    override class func spec() {
        var target: MockTransitionTarget!
        var coordinator: WindowTransitionCoordinator<MockTransitionTarget>!
        var screen1: TestScreen!
        var screen2: TestScreen!
        var screen3: TestScreen!
        var window: TestWindow!

        beforeEach {
            target = MockTransitionTarget()
            coordinator = WindowTransitionCoordinator<MockTransitionTarget>()
            coordinator.target = target
            screen1 = TestScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
            screen2 = TestScreen(frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
            screen3 = TestScreen(frame: CGRect(x: 3840, y: 0, width: 1920, height: 1080))
            target.screens = [screen1, screen2, screen3]

            window = TestWindow(element: nil)!
            window.currentScreen = screen1
            TestWindow.focused = window
        }

        afterEach {
            TestWindow.focused = nil
        }

        describe("swapFocusedWindowScreenClockwise") {
            context("when focused window is floating") {
                it("moves the window to the next screen clockwise") {
                    target.floatingWindowIDs.insert(window.id())

                    coordinator.swapFocusedWindowScreenClockwise()

                    expect(target.executedTransitions).to(haveCount(1))
                    guard case let .moveWindowToScreen(movedWindow, screen)? = target.executedTransitions.first else {
                        fail("Expected .moveWindowToScreen transition")
                        return
                    }
                    expect(movedWindow.id()).to(equal(window.id()))
                    expect(screen.screenID()).to(equal(screen2.screenID()))
                }
            }

            context("when focused window is not floating") {
                it("moves the window to the next screen clockwise") {
                    coordinator.swapFocusedWindowScreenClockwise()

                    expect(target.executedTransitions).to(haveCount(1))
                    guard case let .moveWindowToScreen(movedWindow, screen)? = target.executedTransitions.first else {
                        fail("Expected .moveWindowToScreen transition")
                        return
                    }
                    expect(movedWindow.id()).to(equal(window.id()))
                    expect(screen.screenID()).to(equal(screen2.screenID()))
                }
            }

            context("when there is no focused window") {
                it("resets focus") {
                    TestWindow.focused = nil

                    coordinator.swapFocusedWindowScreenClockwise()

                    expect(target.executedTransitions).to(haveCount(1))
                    guard case .resetFocus? = target.executedTransitions.first else {
                        fail("Expected .resetFocus transition")
                        return
                    }
                }
            }

            context("when focused window has no screen") {
                it("does not execute any transition") {
                    window.currentScreen = nil

                    coordinator.swapFocusedWindowScreenClockwise()

                    expect(target.executedTransitions).to(beEmpty())
                }
            }

            context("when target has no next screen") {
                it("does not execute any transition") {
                    target.screens = []

                    coordinator.swapFocusedWindowScreenClockwise()

                    expect(target.executedTransitions).to(beEmpty())
                }
            }
        }

        describe("swapFocusedWindowScreenCounterClockwise") {
            context("when focused window is floating") {
                it("moves the window to the next screen counter-clockwise") {
                    target.floatingWindowIDs.insert(window.id())

                    coordinator.swapFocusedWindowScreenCounterClockwise()

                    expect(target.executedTransitions).to(haveCount(1))
                    guard case let .moveWindowToScreen(movedWindow, screen)? = target.executedTransitions.first else {
                        fail("Expected .moveWindowToScreen transition")
                        return
                    }
                    expect(movedWindow.id()).to(equal(window.id()))
                    expect(screen.screenID()).to(equal(screen3.screenID()))
                }
            }

            context("when focused window is not floating") {
                it("moves the window to the next screen counter-clockwise") {
                    coordinator.swapFocusedWindowScreenCounterClockwise()

                    expect(target.executedTransitions).to(haveCount(1))
                    guard case let .moveWindowToScreen(movedWindow, screen)? = target.executedTransitions.first else {
                        fail("Expected .moveWindowToScreen transition")
                        return
                    }
                    expect(movedWindow.id()).to(equal(window.id()))
                    expect(screen.screenID()).to(equal(screen3.screenID()))
                }
            }

            context("when there is no focused window") {
                it("resets focus") {
                    TestWindow.focused = nil

                    coordinator.swapFocusedWindowScreenCounterClockwise()

                    expect(target.executedTransitions).to(haveCount(1))
                    guard case .resetFocus? = target.executedTransitions.first else {
                        fail("Expected .resetFocus transition")
                        return
                    }
                }
            }

            context("when focused window has no screen") {
                it("does not execute any transition") {
                    window.currentScreen = nil

                    coordinator.swapFocusedWindowScreenCounterClockwise()

                    expect(target.executedTransitions).to(beEmpty())
                }
            }

            context("when target has no next screen") {
                it("does not execute any transition") {
                    target.screens = []

                    coordinator.swapFocusedWindowScreenCounterClockwise()

                    expect(target.executedTransitions).to(beEmpty())
                }
            }
        }
    }
}
