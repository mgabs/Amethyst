//
//  FourColumnLayout.swift
//  Amethyst
//
//  Originally created by Ian Ynda-Hummel on 12/15/15.
//  Copyright © 2015 Ian Ynda-Hummel. All rights reserved.
//
//  Modifications by Craig Disselkoen on 09/03/18.
//  Modifications by Reyk Floeter on 10/28/21.
//

import Silica

// we'd like to hide these structures and enums behind fileprivate, but
// https://bugs.swift.org/browse/SR-47

enum FourColumn {
    case left
    case middleLeft
    case middleRight
    case right
}

enum FourPane {
    case main
    case secondary
    case tertiary
    case quaternary
}

struct FourPaneWidths {
    var left: CGFloat = 0
    var middleLeft: CGFloat = 0
    var middleRight: CGFloat = 0
    var right: CGFloat = 0
}

struct QuadruplePaneArrangement {
    /// number of windows in pane
    private let paneCount: [FourPane: UInt]

    /// height of windows in pane
    private let paneWindowHeight: [FourPane: CGFloat]

    /// width of windows in pane
    private let paneWindowWidth: [FourPane: CGFloat]

    // how panes relate to columns
    private let panePosition: [FourPane: FourColumn]

    /// how columns relate to panes
    private let columnDesignation: [FourColumn: FourPane]

    /**
     - Parameters:
        - mainPane: which Column is the main Pane
        - numWindows: how many windows total
        - numMainPane: how many windows in the main Pane
        - screenSize: total size of the screen
        - mainPaneRatio: ratio of the screen taken by main pane
     */
    init(mainPane: FourColumn, numWindows: UInt, numMainPane: UInt, screenSize: CGSize, mainPaneRatio: CGFloat) {
        // forward and reverse mapping of columns to their designations
        self.panePosition = {
            switch mainPane {
            case .left: return [.main: .left, .secondary: .middleLeft, .tertiary: .middleRight, .quaternary: .right]
            case .middleLeft: return [.main: .middleLeft, .secondary: .middleRight, .tertiary: .left, .quaternary: .right]
            case .middleRight: return [.main: .middleRight, .secondary: .middleLeft, .tertiary: .right, .quaternary: .left]
            case .right: return [.main: .right, .secondary: .middleRight, .tertiary: .middleLeft, .quaternary: .left]
            }
        }()
        // swap keys and values for reverse lookup
        self.columnDesignation = Dictionary(uniqueKeysWithValues: panePosition.map({ ($1, $0) }))

        // calculate how many are in each type
        let mainPaneCount = min(numWindows, numMainPane)
        let nonMainCount: UInt = numWindows - mainPaneCount
        let secondaryPaneCount: UInt = nonMainCount > 0 ? (nonMainCount + 2) / 3 : 0
        let tertiaryPaneCount: UInt = nonMainCount > 1 ? (nonMainCount + 1) / 3 : 0
        let quaternaryPaneCount: UInt = nonMainCount > 2 ? nonMainCount / 3 : 0
        self.paneCount = [.main: mainPaneCount, .secondary: secondaryPaneCount, .tertiary: tertiaryPaneCount, .quaternary: quaternaryPaneCount]

        // calculate heights
        let screenHeight = screenSize.height
        self.paneWindowHeight = [
            .main: round(screenHeight / CGFloat(mainPaneCount)),
            .secondary: secondaryPaneCount == 0 ? 0.0 : round(screenHeight / CGFloat(secondaryPaneCount)),
            .tertiary: tertiaryPaneCount == 0 ? 0.0 : round(screenHeight / CGFloat(tertiaryPaneCount)),
            .quaternary: quaternaryPaneCount == 0 ? 0.0 : round(screenHeight / CGFloat(quaternaryPaneCount))
        ]

        // calculate widths
        let screenWidth = screenSize.width
        let mainWindowWidth = secondaryPaneCount == 0 ? screenWidth : round(screenWidth * mainPaneRatio)
        let remainingWidth = screenWidth - mainWindowWidth
        let activeNonMainPaneCount = (secondaryPaneCount > 0 ? 1 : 0) + (tertiaryPaneCount > 0 ? 1 : 0) + (quaternaryPaneCount > 0 ? 1 : 0)

        // Divide remaining width evenly among active non-main columns.
        // The last active column absorbs any rounding residual so all widths sum to exactly screenWidth.
        let colWidth = activeNonMainPaneCount == 0 ? 0.0 : round(remainingWidth / CGFloat(activeNonMainPaneCount))
        let (secondaryWidth, tertiaryWidth, quaternaryWidth): (CGFloat, CGFloat, CGFloat) = {
            switch activeNonMainPaneCount {
            case 1: return (remainingWidth, 0, 0)
            case 2: return (colWidth, remainingWidth - colWidth, 0)
            case 3: return (colWidth, colWidth, remainingWidth - colWidth * 2)
            default: return (0, 0, 0)
            }
        }()

        self.paneWindowWidth = [
            .main: mainWindowWidth,
            .secondary: secondaryWidth,
            .tertiary: tertiaryWidth,
            .quaternary: quaternaryWidth
        ]
   }

    func count(_ pane: FourPane) -> UInt {
        return paneCount[pane]!
    }

    func height(_ pane: FourPane) -> CGFloat {
        return paneWindowHeight[pane]!
    }

    func width(_ pane: FourPane) -> CGFloat {
        return paneWindowWidth[pane]!
    }

    func firstIndex(_ pane: FourPane) -> UInt {
        switch pane {
        case .main: return 0
        case .secondary: return count(.main)
        case .tertiary: return count(.main) + count(.secondary)
        case .quaternary: return count(.main) + count(.secondary) + count(.tertiary)
        }
    }

    func pane(ofIndex windowIndex: UInt) -> FourPane {
        if windowIndex >= firstIndex(.quaternary) {
            return .quaternary
        }
        if windowIndex >= firstIndex(.tertiary) {
            return .tertiary
        }
        if windowIndex >= firstIndex(.secondary) {
            return .secondary
        }
        return .main
    }

    /// Given a window index, which Pane does it belong to, and which index within that Pane
    func coordinates(at windowIndex: UInt) -> (FourPane, UInt) {
        let pane = self.pane(ofIndex: windowIndex)
        return (pane, windowIndex - firstIndex(pane))
    }

    /// Get the (height, width) dimensions for a window in the given Pane
    func windowDimensions(inPane pane: FourPane) -> (CGFloat, CGFloat) {
        return (height(pane), width(pane))
    }

    /// Get the Column assignment for the given Pane
    func column(ofPane pane: FourPane) -> FourColumn {
        return panePosition[pane]!
    }

    func pane(ofColumn column: FourColumn) -> FourPane {
        return columnDesignation[column]!
    }

    /// Get the column widths in the order (left, middle, right)
    func widthsLeftToRight() -> FourPaneWidths {
        return FourPaneWidths(
            left: width(pane(ofColumn: .left)),
            middleLeft: width(pane(ofColumn: .middleLeft)),
            middleRight: width(pane(ofColumn: .middleRight)),
            right: width(pane(ofColumn: .right))
        )
    }
}

// not an actual Layout, just a base class for the four actual Layouts below
class FourColumnLayout<Window: WindowType>: Layout<Window> {
    class var mainColumn: FourColumn { fatalError("Must be implemented by subclass") }

    enum CodingKeys: String, CodingKey {
        case mainPaneCount
        case mainPaneRatio
    }

    private(set) var mainPaneCount: Int = 1
    private(set) var mainPaneRatio: CGFloat = 0.5

    required init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.mainPaneCount = try values.decode(Int.self, forKey: .mainPaneCount)
        self.mainPaneRatio = try values.decode(CGFloat.self, forKey: .mainPaneRatio)
        super.init()
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mainPaneCount, forKey: .mainPaneCount)
        try container.encode(mainPaneRatio, forKey: .mainPaneRatio)
    }

    override func frameAssignments(_ windowSet: WindowSet<Window>, on screen: Screen) -> [FrameAssignment<Window>]? {
        let windows = windowSet.windows

        guard !windows.isEmpty else {
            return []
        }

        let screenFrame = screen.adjustedFrame()
        let paneArrangement = QuadruplePaneArrangement(
            mainPane: type(of: self).mainColumn,
            numWindows: UInt(windows.count),
            numMainPane: UInt(mainPaneCount),
            screenSize: screenFrame.size,
            mainPaneRatio: mainPaneRatio
        )

        return windows.reduce([]) { frameAssignments, window -> [FrameAssignment<Window>] in
            var assignments = frameAssignments
            var windowFrame = CGRect.zero
            let windowIndex: UInt = UInt(frameAssignments.count)

            let (pane, paneIndex) = paneArrangement.coordinates(at: windowIndex)

            let (windowHeight, windowWidth): (CGFloat, CGFloat) = paneArrangement.windowDimensions(inPane: pane)
            let column: FourColumn = paneArrangement.column(ofPane: pane)

            let widths = paneArrangement.widthsLeftToRight()

            let xorigin: CGFloat = screenFrame.origin.x + {
                switch column {
                case .left: return 0.0
                case .middleLeft: return widths.left
                case .middleRight: return widths.left + widths.middleLeft
                case .right: return widths.left + widths.middleLeft + widths.middleRight
                }
            }()

            let scaleFactor: CGFloat = screenFrame.width / {
                if pane == .main {
                    return paneArrangement.width(.main)
                }
                return paneArrangement.width(.secondary) + paneArrangement.width(.tertiary) + paneArrangement.width(.quaternary)
            }()

            windowFrame.origin.x = xorigin
            windowFrame.origin.y = screenFrame.origin.y + (windowHeight * CGFloat(paneIndex))
            windowFrame.size.width = windowWidth
            windowFrame.size.height = windowHeight

            let isMain = windowIndex < paneArrangement.firstIndex(.secondary)

            let resizeRules = ResizeRules(
                isMain: isMain,
                unconstrainedDimension: .horizontal,
                scaleFactor: scaleFactor,
                windowMargins: self.windowMargins,
                windowMarginSize: self.windowMarginSize
            )
            let frameAssignment = FrameAssignment<Window>(
                frame: windowFrame,
                window: window,
                screenFrame: screenFrame,
                resizeRules: resizeRules,
                windowMargins: self.windowMargins,
                windowMarginSize: self.windowMarginSize
            )

            assignments.append(frameAssignment)

            return assignments
        }
    }
}

extension FourColumnLayout {
    func recommendMainPaneRawRatio(rawRatio: CGFloat) {
        mainPaneRatio = rawRatio
    }

    func increaseMainPaneCount() {
        mainPaneCount += 1
    }

    func decreaseMainPaneCount() {
        mainPaneCount = max(1, mainPaneCount - 1)
    }
}

// implement the two variants
class FourColumnLeftLayout<Window: WindowType>: FourColumnLayout<Window>, PanedLayout {
    override static var layoutName: String { return "4Column Left" }
    override static var layoutKey: String { return "4column-left" }
    override static var mainColumn: FourColumn { return .middleLeft }
}

class FourColumnRightLayout<Window: WindowType>: FourColumnLayout<Window>, PanedLayout {
    override static var layoutName: String { return "4Column Right" }
    override static var layoutKey: String { return "4column-right" }
    override static var mainColumn: FourColumn { return .middleRight }
}
