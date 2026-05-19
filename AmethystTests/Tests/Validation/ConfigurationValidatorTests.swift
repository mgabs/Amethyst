@testable import Amethyst
import XCTest

final class ValidationErrorTests: XCTestCase {
    func testConfigurationInvalidErrorDescription() {
        let error = ValidationError.configurationInvalid("test message")
        XCTAssertEqual(error.errorDescription, "Invalid configuration: test message")
    }

    func testFrameBoundsInvalidErrorDescription() {
        let error = ValidationError.frameBoundsInvalid("frame out of bounds")
        XCTAssertEqual(error.errorDescription, "Invalid frame bounds: frame out of bounds")
    }

    func testLayoutIndexOutOfBoundsErrorDescription() {
        let error = ValidationError.layoutIndexOutOfBounds(index: 5, count: 3)
        XCTAssertEqual(error.errorDescription, "Layout index 5 is out of bounds (count: 3)")
    }
}
