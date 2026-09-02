import Silica
import XCTest

final class SISpaceTests: XCTestCase {
    private let screenDescription: [AnyHashable: Any] = [
        "Display Identifier": "Main",
        "Current Space": ["ManagedSpaceID": 5, "type": 0, "uuid": "B"],
        "Spaces": [
            ["ManagedSpaceID": 4, "type": 0, "uuid": "A"],
            ["ManagedSpaceID": 5, "type": 0, "uuid": "B"],
            ["ManagedSpaceID": 9, "type": 4, "uuid": "C", "TileLayoutManager": [:]],
            ["uuid": "malformed, no id"]
        ]
    ]

    func testParsesSpacesInOrderAndSkipsMalformed() {
        let spaces = SISpace.spaces(withScreenDescription: screenDescription)
        XCTAssertEqual(spaces.map { $0.spaceID }, [4, 5, 9])
        XCTAssertEqual(spaces.map { $0.uuid }, ["A", "B", "C"])
        XCTAssertEqual(spaces.map { $0.isFullscreen }, [false, false, true])
        XCTAssertEqual(spaces[0].type, CGSSpaceTypeUser)
        XCTAssertEqual(spaces[2].type.rawValue, 4)
    }

    func testCurrentSpace() {
        let current = SISpace.currentSpace(withScreenDescription: screenDescription)
        XCTAssertEqual(current?.spaceID, 5)
        XCTAssertEqual(current, SISpace.spaces(withScreenDescription: screenDescription)[1])
    }

    func testEqualityIsBySpaceID() {
        let a = SISpace(spaceID: 7, type: CGSSpaceTypeUser, uuid: "x", isFullscreen: false)
        let b = SISpace(spaceID: 7, type: CGSSpaceTypeUser, uuid: "different", isFullscreen: true)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hash, b.hash)
    }

    func testMissingKeysYieldEmpty() {
        XCTAssertEqual(SISpace.spaces(withScreenDescription: [:]).count, 0)
        XCTAssertNil(SISpace.currentSpace(withScreenDescription: [:]))
    }
}
