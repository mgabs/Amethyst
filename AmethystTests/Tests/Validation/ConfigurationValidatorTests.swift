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

final class ConfigurationValidatorTests: XCTestCase {
    private let validator = ConfigurationValidator()

    func testValidateMainPaneRatio_acceptsValidValue() {
        XCTAssertNil(validator.validateMainPaneRatio(0.5))
    }

    func testValidateMainPaneRatio_rejectsNegative() {
        let error = validator.validateMainPaneRatio(-0.1)
        XCTAssertNotNil(error)
    }

    func testValidateMainPaneRatio_rejectsGreaterThanOne() {
        let error = validator.validateMainPaneRatio(1.5)
        XCTAssertNotNil(error)
    }

    func testValidateFocusFollowsMouseDelay_acceptsValidValue() {
        XCTAssertNil(validator.validateFocusFollowsMouseDelay(0.5))
    }

    func testValidateFocusFollowsMouseDelay_rejectsNegative() {
        let error = validator.validateFocusFollowsMouseDelay(-0.1)
        XCTAssertNotNil(error)
    }

    func testValidateWindowMarginSize_acceptsValidValue() {
        XCTAssertNil(validator.validateWindowMarginSize(10))
    }

    func testValidateWindowMarginSize_rejectsNegative() {
        let error = validator.validateWindowMarginSize(-1)
        XCTAssertNotNil(error)
    }
}
