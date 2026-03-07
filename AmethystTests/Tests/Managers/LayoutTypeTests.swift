//
//  LayoutTypeTests.swift
//  AmethystTests
//
//  Created by Ian Ynda-Hummel on 3/6/26.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import Nimble
import Quick

class LayoutTypeTests: QuickSpec {
    override func spec() {
        describe("LayoutType") {
            describe("from(key:)") {
                it("returns the correct layout type for each key") {
                    expect(LayoutType<TestWindow>.from(key: "tall")).to(equal(.tall))
                    expect(LayoutType<TestWindow>.from(key: "tall-right")).to(equal(.tallRight))
                    expect(LayoutType<TestWindow>.from(key: "wide")).to(equal(.wide))
                    expect(LayoutType<TestWindow>.from(key: "two-pane")).to(equal(.twoPane))
                    expect(LayoutType<TestWindow>.from(key: "two-pane-right")).to(equal(.twoPaneRight))
                    expect(LayoutType<TestWindow>.from(key: "3column-left")).to(equal(.threeColumnLeft))
                    expect(LayoutType<TestWindow>.from(key: "middle-wide")).to(equal(.threeColumnMiddle))
                    expect(LayoutType<TestWindow>.from(key: "3column-right")).to(equal(.threeColumnRight))
                    expect(LayoutType<TestWindow>.from(key: "4column-left")).to(equal(.fourColumnLeft))
                    expect(LayoutType<TestWindow>.from(key: "4column-right")).to(equal(.fourColumnRight))
                    expect(LayoutType<TestWindow>.from(key: "fullscreen")).to(equal(.fullscreen))
                    expect(LayoutType<TestWindow>.from(key: "column")).to(equal(.column))
                    expect(LayoutType<TestWindow>.from(key: "row")).to(equal(.row))
                    expect(LayoutType<TestWindow>.from(key: "floating")).to(equal(.floating))
                    expect(LayoutType<TestWindow>.from(key: "widescreen-tall")).to(equal(.widescreenTallLeft))
                    expect(LayoutType<TestWindow>.from(key: "widescreen-tall-right")).to(equal(.widescreenTallRight))
                    expect(LayoutType<TestWindow>.from(key: "bsp")).to(equal(.binarySpacePartitioning))
                }

                it("returns custom layout for unknown keys") {
                    let customKey = "custom-layout-key"
                    let layoutType = LayoutType<TestWindow>.from(key: customKey)
                    if case .custom(let key) = layoutType {
                        expect(key).to(equal(customKey))
                    } else {
                        fail("Expected custom layout type")
                    }
                }
            }
        }
    }
}

extension LayoutType: Equatable {
    public static func == (lhs: LayoutType<Window>, rhs: LayoutType<Window>) -> Bool {
        switch (lhs, rhs) {
        case (.tall, .tall): return true
        case (.tallRight, .tallRight): return true
        case (.wide, .wide): return true
        case (.twoPane, .twoPane): return true
        case (.twoPaneRight, .twoPaneRight): return true
        case (.threeColumnLeft, .threeColumnLeft): return true
        case (.threeColumnMiddle, .threeColumnMiddle): return true
        case (.threeColumnRight, .threeColumnRight): return true
        case (.fourColumnLeft, .fourColumnLeft): return true
        case (.fourColumnRight, .fourColumnRight): return true
        case (.fullscreen, .fullscreen): return true
        case (.column, .column): return true
        case (.row, .row): return true
        case (.floating, .floating): return true
        case (.widescreenTallLeft, .widescreenTallLeft): return true
        case (.widescreenTallRight, .widescreenTallRight): return true
        case (.binarySpacePartitioning, .binarySpacePartitioning): return true
        case (.custom(let key1), .custom(let key2)): return key1 == key2
        default: return false
        }
    }
}
