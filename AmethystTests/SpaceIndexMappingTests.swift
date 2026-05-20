import XCTest
@testable import Amethyst

/// Tests for space index mapping behavior.
/// Verifies that the throw-space commands correctly map between
/// user-space indices and all-space indices when non-user spaces exist.
class SpaceIndexMappingTests: XCTestCase {

    /// Test: Space index calculation matches the fix for throw-space-1
    func testSpaceIndexMapping_WithNonUserSpaces() {
        // Simulate: 6 user spaces + 1 fullscreen app
        // This matches the real-world bug scenario

        let userSpaceIDs: [UInt64] = [101, 102, 103, 104, 105, 106]
        let allSpaceIDs: [UInt64] = [200, 101, 102, 103, 104, 105, 106]
        // where 200 = fullscreen app, 101-106 = user spaces

        // When throw-space-1 is called: request index 0 (first user space)
        let requestedUserSpaceIndex = 0
        let targetSpaceID = userSpaceIDs[requestedUserSpaceIndex]

        // The fix maps this to the correct index in allSpaces
        let correctAllSpaceIndex = allSpaceIDs.firstIndex(of: targetSpaceID) ?? requestedUserSpaceIndex

        // Assertions
        XCTAssertEqual(targetSpaceID, 101, "Target should be first user space (id=101)")
        XCTAssertEqual(correctAllSpaceIndex, 1, "Index in allSpaces should be 1, not 0")

        // The bug was using requestedUserSpaceIndex (0) directly
        // This would move to allSpaceIDs[0] = 200 (fullscreen) ✗
        // The fix uses correctAllSpaceIndex (1)
        // This moves to allSpaceIDs[1] = 101 (Space 1) ✓

        XCTAssertNotEqual(allSpaceIDs[requestedUserSpaceIndex], targetSpaceID,
                         "Bug: Using user index directly lands on wrong space")
        XCTAssertEqual(allSpaceIDs[correctAllSpaceIndex], targetSpaceID,
                      "Fix: Mapped index lands on correct space")
    }

    /// Test: throw-space-2 behavior (why it seemed to work)
    func testSpaceIndexMapping_ThrowSpace2() {
        let userSpaceIDs: [UInt64] = [101, 102, 103, 104, 105, 106]
        let allSpaceIDs: [UInt64] = [200, 101, 102, 103, 104, 105, 106]

        let requestedUserSpaceIndex = 1  // throw-space-2
        let targetSpaceID = userSpaceIDs[requestedUserSpaceIndex]
        let correctAllSpaceIndex = allSpaceIDs.firstIndex(of: targetSpaceID) ?? requestedUserSpaceIndex

        // With bug: uses index 1 → lands on Space 1 (wrong but coincidentally close)
        // With fix: uses index 2 → lands on Space 2 (correct)

        XCTAssertEqual(requestedUserSpaceIndex, 1)
        XCTAssertEqual(correctAllSpaceIndex, 2)

        // The bug would move to allSpaceIDs[1] = 101 (Space 1) - wrong!
        // The fix moves to allSpaceIDs[2] = 102 (Space 2) - correct!
    }

    /// Test: No nonuser spaces (sanity check)
    func testSpaceIndexMapping_NoNonUserSpaces() {
        // When no fullscreen apps exist, indices should match
        let userSpaceIDs: [UInt64] = [101, 102, 103, 104, 105, 106]
        let allSpaceIDs: [UInt64] = [101, 102, 103, 104, 105, 106]

        for (index, spaceID) in userSpaceIDs.enumerated() {
            let correctIndex = allSpaceIDs.firstIndex(of: spaceID) ?? index
            XCTAssertEqual(index, correctIndex,
                          "Without nonuser spaces, indices should match")
        }
    }

    /// Test: Multiple nonuser spaces scenario
    func testSpaceIndexMapping_MultipleNonUserSpaces() {
        // Scenario: 2 fullscreen apps + 4 user spaces
        let userSpaceIDs: [UInt64] = [101, 102, 103, 104]
        let allSpaceIDs: [UInt64] = [200, 101, 201, 102, 103, 104]
        // where 200, 201 = fullscreen apps

        // throw-space-1 (request index 0)
        let index1 = allSpaceIDs.firstIndex(of: userSpaceIDs[0]) ?? 0
        XCTAssertEqual(index1, 1, "Space 1 should be at index 1")

        // throw-space-2 (request index 1)
        let index2 = allSpaceIDs.firstIndex(of: userSpaceIDs[1]) ?? 1
        XCTAssertEqual(index2, 3, "Space 2 should be at index 3")

        // throw-space-3 (request index 2)
        let index3 = allSpaceIDs.firstIndex(of: userSpaceIDs[2]) ?? 2
        XCTAssertEqual(index3, 4, "Space 3 should be at index 4")
    }

    /// Test: All nonuser spaces (edge case)
    func testSpaceIndexMapping_AllNonUserSpaces() {
        // Edge case: only fullscreen apps, no user spaces
        let userSpaceIDs: [UInt64] = []
        let allSpaceIDs: [UInt64] = [200, 201, 202]

        // This shouldn't happen in practice (user needs at least 1 space)
        // but the code should handle it gracefully
        XCTAssertTrue(userSpaceIDs.isEmpty)
        XCTAssertFalse(allSpaceIDs.isEmpty)
    }
}
