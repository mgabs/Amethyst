//
//  FourColumnLayoutTests.swift
//  AmethystTests
//

@testable import Amethyst
import Nimble
import Quick
import Silica

class FourColumnLayoutTests: QuickSpec {
    override class func spec() {
        afterEach {
            TestScreen.availableScreens = []
        }

        describe("QuadruplePaneArrangement") {
            describe("pane counts") {
                it("takes windows in main pane up to provided count") {
                    let mainPaneCount: UInt = 2
                    let screenSize = CGSize(width: 2000, height: 1000)
                    let count: (UInt) -> UInt = { windowCount in
                        QuadruplePaneArrangement(
                            mainPane: .left,
                            numWindows: windowCount,
                            numMainPane: mainPaneCount,
                            screenSize: screenSize,
                            mainPaneRatio: 0.5
                        ).count(.main)
                    }

                    expect(count(1)).to(equal(1))
                    expect(count(2)).to(equal(2))
                    expect(count(5)).to(equal(2))
                }

                it("distributes non-main windows across three panes with ceiling division") {
                    let screenSize = CGSize(width: 2000, height: 1000)
                    let arrangement: (UInt) -> QuadruplePaneArrangement = { windowCount in
                        QuadruplePaneArrangement(
                            mainPane: .left,
                            numWindows: windowCount,
                            numMainPane: 0,
                            screenSize: screenSize,
                            mainPaneRatio: 0.5
                        )
                    }

                    // secondary = ceil(n/3), tertiary = ceil((n-1)/3), quaternary = floor(n/3)
                    // counts verified: secondary + tertiary + quaternary == nonMainCount
                    struct TestCase {
                        let numWindows: UInt
                        let expectedSecondary: UInt
                        let expectedTertiary: UInt
                        let expectedQuaternary: UInt
                    }

                    let cases = [
                        TestCase(numWindows: 0, expectedSecondary: 0, expectedTertiary: 0, expectedQuaternary: 0),
                        TestCase(numWindows: 1, expectedSecondary: 1, expectedTertiary: 0, expectedQuaternary: 0),
                        TestCase(numWindows: 2, expectedSecondary: 1, expectedTertiary: 1, expectedQuaternary: 0),
                        TestCase(numWindows: 3, expectedSecondary: 1, expectedTertiary: 1, expectedQuaternary: 1),
                        TestCase(numWindows: 4, expectedSecondary: 2, expectedTertiary: 1, expectedQuaternary: 1),
                        TestCase(numWindows: 5, expectedSecondary: 2, expectedTertiary: 2, expectedQuaternary: 1),
                        TestCase(numWindows: 6, expectedSecondary: 2, expectedTertiary: 2, expectedQuaternary: 2),
                        TestCase(numWindows: 7, expectedSecondary: 3, expectedTertiary: 2, expectedQuaternary: 2),
                        TestCase(numWindows: 8, expectedSecondary: 3, expectedTertiary: 3, expectedQuaternary: 2),
                        TestCase(numWindows: 9, expectedSecondary: 3, expectedTertiary: 3, expectedQuaternary: 3)
                    ]
                    for testCase in cases {
                        let arr = arrangement(testCase.numWindows)
                        expect(arr.count(.secondary)).to(equal(testCase.expectedSecondary), description: "\(testCase.numWindows) windows: secondary")
                        expect(arr.count(.tertiary)).to(equal(testCase.expectedTertiary), description: "\(testCase.numWindows) windows: tertiary")
                        expect(arr.count(.quaternary)).to(equal(testCase.expectedQuaternary), description: "\(testCase.numWindows) windows: quaternary")
                        expect(arr.count(.secondary) + arr.count(.tertiary) + arr.count(.quaternary)).to(equal(testCase.numWindows), description: "\(testCase.numWindows) windows: total sum")
                    }
                }
            }

            it("column widths sum to screen width for all non-main counts") {
                let screenWidth: CGFloat = 2000
                let screenSize = CGSize(width: screenWidth, height: 1000)
                for numWindows: UInt in 0...9 {
                    let arr = QuadruplePaneArrangement(
                        mainPane: .left,
                        numWindows: numWindows,
                        numMainPane: 0,
                        screenSize: screenSize,
                        mainPaneRatio: 0.5
                    )
                    let total = arr.width(.main) + arr.width(.secondary) + arr.width(.tertiary) + arr.width(.quaternary)
                    expect(total).to(equal(screenWidth), description: "\(numWindows) windows: widths must sum to \(screenWidth)")
                }
            }
        }

        describe("left layout") {
            it("separates into a main pane in the second column and three side panes") {
                let screen = TestScreen(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000)))
                TestScreen.availableScreens = [screen]

                let windows = [
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!
                ]
                let layoutWindows = windows.map {
                    LayoutWindow<TestWindow>(id: $0.id(), frame: $0.frame(), isFocused: false)
                }
                let windowSet = WindowSet<TestWindow>(
                    windows: layoutWindows,
                    isWindowWithIDActive: { _ in return true },
                    isWindowWithIDFloating: { _ in return false },
                    windowForID: { id in return windows.first { $0.id() == id } }
                )
                let layout = FourColumnLeftLayout<TestWindow>()
                let frameAssignments = layout.frameAssignments(windowSet, on: screen)!

                expect(layout.mainPaneCount).to(equal(1))

                // FourColumnLeft: mainColumn = .middleLeft
                // main→middleLeft, secondary→middleRight, tertiary→left
                // With 3 windows (1 main, 1 secondary, 1 tertiary) at ratio 0.5:
                // mainWidth=1000, remaining=1000, colWidth=500
                // tertiary(left)=0..500, main(middleLeft)=500..1500, secondary(middleRight)=1500..2000
                let mainAssignment = frameAssignments.forWindows(windows[..<1])
                let nonMainAssignments = frameAssignments.forWindows(windows[1...])

                mainAssignment.verify(frames: [
                    CGRect(x: 500, y: 0, width: 1000, height: 1000)
                ])
                nonMainAssignments.verify(frames: [
                    CGRect(x: 1500, y: 0, width: 500, height: 1000),
                    CGRect(x: 0, y: 0, width: 500, height: 1000)
                ])
            }

            it("handles non-origin screens") {
                let screen = TestScreen(frame: CGRect(x: 100, y: 100, width: 2000, height: 1000))
                TestScreen.availableScreens = [screen]

                let windows = [
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!
                ]
                let layoutWindows = windows.map {
                    LayoutWindow<TestWindow>(id: $0.id(), frame: $0.frame(), isFocused: false)
                }
                let windowSet = WindowSet<TestWindow>(
                    windows: layoutWindows,
                    isWindowWithIDActive: { _ in return true },
                    isWindowWithIDFloating: { _ in return false },
                    windowForID: { id in return windows.first { $0.id() == id } }
                )
                let layout = FourColumnLeftLayout<TestWindow>()
                let frameAssignments = layout.frameAssignments(windowSet, on: screen)!

                let mainAssignment = frameAssignments.forWindows(windows[..<1])
                let nonMainAssignments = frameAssignments.forWindows(windows[1...])

                mainAssignment.verify(frames: [
                    CGRect(x: 600, y: 100, width: 1000, height: 1000)
                ])
                nonMainAssignments.verify(frames: [
                    CGRect(x: 1600, y: 100, width: 500, height: 1000),
                    CGRect(x: 100, y: 100, width: 500, height: 1000)
                ])
            }

            it("fills all four columns with four or more windows") {
                let screen = TestScreen(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000)))
                TestScreen.availableScreens = [screen]

                // 4 windows: 1 main, 1 secondary, 1 tertiary, 1 quaternary
                let windows = (0..<4).map { _ in TestWindow(element: nil)! }
                let layoutWindows = windows.map {
                    LayoutWindow<TestWindow>(id: $0.id(), frame: $0.frame(), isFocused: false)
                }
                let windowSet = WindowSet<TestWindow>(
                    windows: layoutWindows,
                    isWindowWithIDActive: { _ in return true },
                    isWindowWithIDFloating: { _ in return false },
                    windowForID: { id in return windows.first { $0.id() == id } }
                )
                let layout = FourColumnLeftLayout<TestWindow>()
                let frameAssignments = layout.frameAssignments(windowSet, on: screen)!

                // mainWidth=1000, remaining=1000, colWidth=round(1000/3)=333
                // tertiary(left)=333, main(middleLeft)=1000, secondary(middleRight)=333, quaternary(right)=334
                // x offsets: left=0, middleLeft=333, middleRight=1333, right=1666
                let mainAssignment = frameAssignments.forWindows(windows[..<1])
                let secondaryAssignment = frameAssignments.forWindows(windows[1..<2])
                let tertiaryAssignment = frameAssignments.forWindows(windows[2..<3])
                let quaternaryAssignment = frameAssignments.forWindows(windows[3...])

                mainAssignment.verify(frames: [
                    CGRect(x: 333, y: 0, width: 1000, height: 1000)
                ])
                secondaryAssignment.verify(frames: [
                    CGRect(x: 1333, y: 0, width: 333, height: 1000)
                ])
                tertiaryAssignment.verify(frames: [
                    CGRect(x: 0, y: 0, width: 333, height: 1000)
                ])
                quaternaryAssignment.verify(frames: [
                    CGRect(x: 1666, y: 0, width: 334, height: 1000)
                ])
            }

            it("changes distribution based on pane ratio") {
                let screen = TestScreen(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000)))
                TestScreen.availableScreens = [screen]

                let windows = [
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!
                ]
                let layoutWindows = windows.map {
                    LayoutWindow<TestWindow>(id: $0.id(), frame: $0.frame(), isFocused: false)
                }
                let windowSet = WindowSet<TestWindow>(
                    windows: layoutWindows,
                    isWindowWithIDActive: { _ in return true },
                    isWindowWithIDFloating: { _ in return false },
                    windowForID: { id in return windows.first { $0.id() == id } }
                )
                let layout = FourColumnLeftLayout<TestWindow>()

                layout.recommendMainPaneRatio(0.75)
                expect(layout.mainPaneRatio).to(equal(0.75))

                // mainWidth=round(2000*0.75)=1500, remaining=500, colWidth=250
                // tertiary(left)=0..250, main(middleLeft)=250..1750, secondary(middleRight)=1750..2000
                var frameAssignments = layout.frameAssignments(windowSet, on: screen)!
                frameAssignments.forWindows(windows[..<1]).verify(frames: [
                    CGRect(x: 250, y: 0, width: 1500, height: 1000)
                ])
                frameAssignments.forWindows(windows[1...]).verify(frames: [
                    CGRect(x: 1750, y: 0, width: 250, height: 1000),
                    CGRect(x: 0, y: 0, width: 250, height: 1000)
                ])

                layout.recommendMainPaneRatio(0.25)
                expect(layout.mainPaneRatio).to(equal(0.25))

                // mainWidth=round(2000*0.25)=500, remaining=1500, colWidth=750
                // tertiary(left)=0..750, main(middleLeft)=750..1250, secondary(middleRight)=1250..2000
                frameAssignments = layout.frameAssignments(windowSet, on: screen)!
                frameAssignments.forWindows(windows[..<1]).verify(frames: [
                    CGRect(x: 750, y: 0, width: 500, height: 1000)
                ])
                frameAssignments.forWindows(windows[1...]).verify(frames: [
                    CGRect(x: 1250, y: 0, width: 750, height: 1000),
                    CGRect(x: 0, y: 0, width: 750, height: 1000)
                ])
            }

            describe("coding") {
                it("encodes and decodes") {
                    let layout = FourColumnLeftLayout<TestWindow>()
                    layout.increaseMainPaneCount()
                    layout.recommendMainPaneRatio(0.45)

                    expect(layout.mainPaneCount).to(equal(2))
                    expect(layout.mainPaneRatio).to(equal(0.45))

                    let encodedLayout = try! JSONEncoder().encode(layout)
                    let decodedLayout = try! JSONDecoder().decode(FourColumnLeftLayout<TestWindow>.self, from: encodedLayout)

                    expect(decodedLayout.mainPaneCount).to(equal(2))
                    expect(decodedLayout.mainPaneRatio).to(equal(0.45))
                }
            }
        }

        describe("right layout") {
            it("separates into a main pane in the third column and three side panes") {
                let screen = TestScreen(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000)))
                TestScreen.availableScreens = [screen]

                let windows = [
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!,
                    TestWindow(element: nil)!
                ]
                let layoutWindows = windows.map {
                    LayoutWindow<TestWindow>(id: $0.id(), frame: $0.frame(), isFocused: false)
                }
                let windowSet = WindowSet<TestWindow>(
                    windows: layoutWindows,
                    isWindowWithIDActive: { _ in return true },
                    isWindowWithIDFloating: { _ in return false },
                    windowForID: { id in return windows.first { $0.id() == id } }
                )
                let layout = FourColumnRightLayout<TestWindow>()
                let frameAssignments = layout.frameAssignments(windowSet, on: screen)!

                expect(layout.mainPaneCount).to(equal(1))

                // FourColumnRight: mainColumn = .middleRight
                // main→middleRight, secondary→middleLeft, tertiary→right
                // quaternary(left)=0, secondary(middleLeft)=0..500, main(middleRight)=500..1500, tertiary(right)=1500..2000
                let mainAssignment = frameAssignments.forWindows(windows[..<1])
                let nonMainAssignments = frameAssignments.forWindows(windows[1...])

                mainAssignment.verify(frames: [
                    CGRect(x: 500, y: 0, width: 1000, height: 1000)
                ])
                nonMainAssignments.verify(frames: [
                    CGRect(x: 0, y: 0, width: 500, height: 1000),
                    CGRect(x: 1500, y: 0, width: 500, height: 1000)
                ])
            }

            describe("coding") {
                it("encodes and decodes") {
                    let layout = FourColumnRightLayout<TestWindow>()
                    layout.increaseMainPaneCount()
                    layout.recommendMainPaneRatio(0.45)

                    expect(layout.mainPaneCount).to(equal(2))
                    expect(layout.mainPaneRatio).to(equal(0.45))

                    let encodedLayout = try! JSONEncoder().encode(layout)
                    let decodedLayout = try! JSONDecoder().decode(FourColumnRightLayout<TestWindow>.self, from: encodedLayout)

                    expect(decodedLayout.mainPaneCount).to(equal(2))
                    expect(decodedLayout.mainPaneRatio).to(equal(0.45))
                }
            }
        }
    }
}
