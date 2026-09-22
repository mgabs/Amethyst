//
//  WindowManagerBorderLifecycleTests.swift
//  AmethystTests
//
//  Created by Mohammed Metawea on 2026-09-22.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import AppKit
import Foundation
import Nimble
import Quick
import Silica

final class WindowManagerBorderLifecycleTests: QuickSpec {
    override class func spec() {
        describe("WindowManagerBorderLifecycle") {
            it("hides border when window moves to a different space") {
                let border = FocusedWindowBorder()
                let targetID: CGWindowID = 555
                let currentSpace: CGSSpaceID = 10
                let remoteSpace: CGSSpaceID = 20

                border.show(around: CGRect(x: 10, y: 10, width: 200, height: 200), below: targetID, in: currentSpace, color: .green, width: 2)
                expect(border.targetWindowID).to(equal(targetID))

                // When window moves to remoteSpace, space matching check fails
                let isStillEligible = FocusedWindowBorder.isEligible(
                    tracked: true,
                    managed: true,
                    spaceType: CGSSpaceTypeUser,
                    windowSpaceID: remoteSpace,
                    screenSpaceID: currentSpace
                )
                expect(isStillEligible).to(beFalse())

                // Hiding matching window ID resets border
                border.hideIfTargetMatches(targetID)
                expect(border.targetWindowID).to(beNil())
            }

            it("hides border immediately when window is closed / removed") {
                let border = FocusedWindowBorder()
                let targetID: CGWindowID = 777

                border.show(around: CGRect(x: 50, y: 50, width: 300, height: 300), below: targetID, in: 1, color: .orange, width: 4)
                expect(border.targetWindowID).to(equal(targetID))

                // Simulate window removal hook
                border.hideIfTargetMatches(targetID)
                expect(border.targetWindowID).to(beNil())
            }

            it("hides border immediately on space transition") {
                let border = FocusedWindowBorder()
                border.show(around: CGRect(x: 0, y: 0, width: 100, height: 100), below: 888, in: 1, color: .red, width: 2)
                expect(border.targetWindowID).to(equal(888))

                // Simulate activeSpaceDidChange pre-emptive hide
                border.hide()
                expect(border.targetWindowID).to(beNil())
            }
        }
    }
}
