//
//  FocusedWindowBorderTests.swift
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

final class FocusedWindowBorderTests: QuickSpec {
    override class func spec() {
        describe("FocusedWindowBorder") {
            it("calculates border frame with outer expansion") {
                let windowFrame = CGRect(x: 100, y: 100, width: 400, height: 300)
                let borderFrame = FocusedWindowBorder.borderFrame(around: windowFrame, width: 4)
                expect(borderFrame).to(equal(CGRect(x: 96, y: 96, width: 408, height: 308)))
            }

            it("converts accessibility frame with top-left origin to AppKit bottom-left origin") {
                let axFrame = CGRect(x: 50, y: 20, width: 200, height: 150)
                let appKitFrame = FocusedWindowBorder.appKitFrame(fromAccessibilityFrame: axFrame, primaryScreenHeight: 1000)
                expect(appKitFrame).to(equal(CGRect(x: 50, y: 830, width: 200, height: 150)))
            }

            it("evaluates eligibility correctly") {
                expect(FocusedWindowBorder.isEligible(tracked: true, managed: true, spaceType: CGSSpaceTypeUser)).to(beTrue())
                expect(FocusedWindowBorder.isEligible(tracked: false, managed: true, spaceType: CGSSpaceTypeUser)).to(beFalse())
                expect(FocusedWindowBorder.isEligible(tracked: true, managed: false, spaceType: CGSSpaceTypeUser)).to(beFalse())
                expect(FocusedWindowBorder.isEligible(tracked: true, managed: true, spaceType: nil)).to(beFalse())
            }

            it("configures layer properties instead of CPU drawing") {
                let border = FocusedWindowBorder()
                let targetFrame = CGRect(x: 100, y: 100, width: 200, height: 100)
                border.show(around: targetFrame, below: 1234, in: 1, color: .red, width: 3)

                guard let borderView = border.contentView else {
                    fail("Missing contentView")
                    return
                }
                expect(borderView.wantsLayer).to(beTrue())
                expect(borderView.layer?.borderWidth).to(equal(3))
                expect(border.frame).to(equal(FocusedWindowBorder.borderFrame(around: targetFrame, width: 3)))
                border.hide()
            }
        }
    }
}
