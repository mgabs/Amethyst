//
//  ReflowOperationTests.swift
//  AmethystTests
//
//  Created by Ian Ynda-Hummel on 3/25/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import Nimble
import Quick
import Silica

class ReflowOperationTests: QuickSpec {
    override func spec() {
        describe("FrameAssignment") {
            it("performs assignment") {
                let screen = TestScreen(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000))
                let window = TestWindow(element: nil)!
                let layoutWindow = LayoutWindow<TestWindow>(id: window.id(), frame: window.frame(), isFocused: false)
                let frameAssignment = FrameAssignment<TestWindow>(
                    frame: CGRect(x: 0, y: 0, width: 1000, height: 1000),
                    window: layoutWindow,
                    screenFrame: screen.frame(),
                    resizeRules: ResizeRules(isMain: true, unconstrainedDimension: .horizontal, scaleFactor: 1),
                    windowMargins: false,
                    windowMarginSize: 0
                )

                frameAssignment.perform(withWindow: window)

                expect(window.frame()).to(equal(frameAssignment.finalFrame))
            }

            it("performs assignment with peeking") {
                let screen = TestScreen(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000))
                let window = TestWindow(element: nil)!
                window.isFocusedValue = true
                let layoutWindow = LayoutWindow<TestWindow>(id: window.id(), frame: window.frame(), isFocused: true)
                let frameAssignment = FrameAssignment<TestWindow>(
                    frame: CGRect(x: 0, y: 0, width: 1000, height: 1000),
                    window: layoutWindow,
                    screenFrame: screen.frame(),
                    resizeRules: ResizeRules(isMain: true, unconstrainedDimension: .horizontal, scaleFactor: 1),
                    windowMargins: false,
                    windowMarginSize: 0
                )

                frameAssignment.perform(withWindow: window)

                expect(window.frame()).to(equal(frameAssignment.finalFrame))
            }

            it("applies margins correctly") {
                let screen = TestScreen(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000))
                let window = TestWindow(element: nil)!
                let layoutWindow = LayoutWindow<TestWindow>(id: window.id(), frame: window.frame(), isFocused: false)
                let marginSize: CGFloat = 20
                let frameAssignment = FrameAssignment<TestWindow>(
                    frame: CGRect(x: 0, y: 0, width: 1000, height: 1000),
                    window: layoutWindow,
                    screenFrame: screen.frame(),
                    resizeRules: ResizeRules(isMain: true, unconstrainedDimension: .horizontal, scaleFactor: 1),
                    windowMargins: true,
                    windowMarginSize: marginSize
                )

                let expectedFrame = CGRect(x: 10, y: 10, width: 980, height: 980)
                expect(frameAssignment.finalFrame).to(equal(expectedFrame))
            }

            it("ignores margins when disabled") {
                let screen = TestScreen(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000))
                let window = TestWindow(element: nil)!
                let layoutWindow = LayoutWindow<TestWindow>(id: window.id(), frame: window.frame(), isFocused: false)
                let marginSize: CGFloat = 20
                let frameAssignment = FrameAssignment<TestWindow>(
                    frame: CGRect(x: 0, y: 0, width: 1000, height: 1000),
                    window: layoutWindow,
                    screenFrame: screen.frame(),
                    resizeRules: ResizeRules(isMain: true, unconstrainedDimension: .horizontal, scaleFactor: 1),
                    windowMargins: false,
                    windowMarginSize: marginSize
                )

                let expectedFrame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
                expect(frameAssignment.finalFrame).to(equal(expectedFrame))
            }
        }
    }
}
