//
//  HotKeyManagerTests.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 4/18/17.
//  Copyright © 2017 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import Nimble
import Quick
import Silica

class HotKeyManagerTests: QuickSpec {
    override class func spec() {
        describe("hotKeyNameToDefaultsKey") {
            it("has the right number of screens") {
                let keyMapping = HotKeyManager<SIApplication>.hotKeyNameToDefaultsKey()
                let screenCommands = keyMapping.filter { $0[1].hasPrefix(CommandKey.focusScreenPrefix.rawValue) }
                expect(screenCommands.count).to(equal(7))
            }
        }
    }
}
