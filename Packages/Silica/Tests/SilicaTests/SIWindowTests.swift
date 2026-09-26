import Silica
import XCTest

final class SIWindowTests: XCTestCase {
    private func description(id: Int, x: Int, y: Int, w: Int, h: Int) -> [AnyHashable: Any] {
        return [
            kCGWindowNumber as String: id,
            kCGWindowBounds as String: ["X": x, "Y": y, "Width": w, "Height": h]
        ]
    }

    func testWindowIDsAtPointPreservesFrontToBackOrderAndSkipsMalformed() {
        let descriptions: [[AnyHashable: Any]] = [
            description(id: 10, x: 0, y: 0, w: 100, h: 100),
            description(id: 11, x: 50, y: 50, w: 100, h: 100),
            description(id: 12, x: 500, y: 500, w: 10, h: 10),
            [kCGWindowNumber as String: 13]
        ]

        XCTAssertEqual(SIWindow.windowIDs(at: CGPoint(x: 75, y: 75), in: descriptions), [10, 11] as [NSNumber])
        XCTAssertEqual(SIWindow.windowIDs(at: CGPoint(x: 120, y: 120), in: descriptions), [11] as [NSNumber])
        XCTAssertEqual(SIWindow.windowIDs(at: CGPoint(x: 1000, y: 1000), in: descriptions), [])
    }

    func testDragPointWithStandardButton() {
        let windowFrame = CGRect(x: 100, y: 50, width: 800, height: 600)
        let buttonFrame = CGRect(x: 130, y: 56, width: 14, height: 14)
        var flags: CGEventFlags = .maskCommand

        let point = SIWindow.dragPoint(windowFrame: windowFrame, buttonFrame: buttonFrame, hasButton: true, outFlags: &flags)

        XCTAssertEqual(point.x, 137, accuracy: 0.001)
        XCTAssertEqual(point.y, 53, accuracy: 0.001)
        XCTAssertEqual(flags.rawValue, 0)
    }

    func testDragPointWithoutButtonFallsBackToTopBorderWithOption() {
        let windowFrame = CGRect(x: 100, y: 50, width: 800, height: 600)
        var flags: CGEventFlags = []

        let point = SIWindow.dragPoint(windowFrame: windowFrame, buttonFrame: .zero, hasButton: false, outFlags: &flags)

        XCTAssertEqual(point.x, 500, accuracy: 0.001)
        XCTAssertEqual(point.y, 52, accuracy: 0.001)
        XCTAssertEqual(flags, .maskAlternate)
    }

    func testDragPointHandlesZeroOrigin() {
        let windowFrame = CGRect(x: 0, y: 0, width: 1000, height: 800)
        var flags: CGEventFlags = []

        let point = SIWindow.dragPoint(windowFrame: windowFrame, buttonFrame: .zero, hasButton: false, outFlags: &flags)

        XCTAssertEqual(point.x, 500, accuracy: 0.001)
        XCTAssertEqual(point.y, 2, accuracy: 0.001)
        XCTAssertEqual(flags, .maskAlternate)
    }
}
