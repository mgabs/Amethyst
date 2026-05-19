@testable import Amethyst
import XCTest

final class LayoutValidatorTests: XCTestCase {
    private var validator: LayoutValidator!

    override func setUp() {
        super.setUp()
        validator = LayoutValidator()
    }

    func testValidateLayoutIndex_acceptsValidIndex() {
        XCTAssertNoThrow(try validator.validateLayoutIndex(0, withinLayoutCount: 5))
    }

    func testValidateLayoutIndex_acceptsLastIndex() {
        XCTAssertNoThrow(try validator.validateLayoutIndex(4, withinLayoutCount: 5))
    }

    func testValidateLayoutIndex_rejectsNegativeIndex() {
        XCTAssertThrowsError(try validator.validateLayoutIndex(-1, withinLayoutCount: 5))
    }

    func testValidateLayoutIndex_rejectsIndexBeyondCount() {
        XCTAssertThrowsError(try validator.validateLayoutIndex(5, withinLayoutCount: 5))
    }

    func testValidateLayoutIndex_rejectsEmptyLayoutList() {
        XCTAssertThrowsError(try validator.validateLayoutIndex(0, withinLayoutCount: 0))
    }
}
