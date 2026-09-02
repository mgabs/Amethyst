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
}
