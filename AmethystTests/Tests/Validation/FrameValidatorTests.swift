@testable import Amethyst
import XCTest

final class FrameValidatorTests: XCTestCase {
    private var validator: FrameValidator!
    private var screenFrame: CGRect!

    override func setUp() {
        super.setUp()
        validator = FrameValidator()
        screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    func testValidateWindowFrame_acceptsValidFrame() {
        let frame = CGRect(x: 100, y: 100, width: 800, height: 600)
        XCTAssertNoThrow(try validator.validateWindowFrame(frame, withinScreen: screenFrame))
    }

    func testValidateWindowFrame_rejectsFrameExceedingRight() {
        // x=1200, width=800 → maxX=2000 > 1920
        let frame = CGRect(x: 1200, y: 100, width: 800, height: 600)
        XCTAssertThrowsError(try validator.validateWindowFrame(frame, withinScreen: screenFrame))
    }

    func testValidateWindowFrame_rejectsFrameExceedingBottom() {
        // y=600, height=600 → maxY=1200 > 1080
        let frame = CGRect(x: 100, y: 600, width: 800, height: 600)
        XCTAssertThrowsError(try validator.validateWindowFrame(frame, withinScreen: screenFrame))
    }

    func testValidateWindowFrame_acceptsMinimalFrame() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertNoThrow(try validator.validateWindowFrame(frame, withinScreen: screenFrame))
    }

    func testValidateWindowFrame_rejectsNegativeWidth() {
        let frame = CGRect(x: 100, y: 100, width: -100, height: 600)
        XCTAssertThrowsError(try validator.validateWindowFrame(frame, withinScreen: screenFrame))
    }

    func testValidateWindowFrame_rejectsNegativeHeight() {
        let frame = CGRect(x: 100, y: 100, width: 800, height: -600)
        XCTAssertThrowsError(try validator.validateWindowFrame(frame, withinScreen: screenFrame))
    }
}
