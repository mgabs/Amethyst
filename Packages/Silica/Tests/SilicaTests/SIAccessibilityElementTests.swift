import Silica
import XCTest

final class SIAccessibilityElementTests: XCTestCase {
    func testSetFlagReportsFailureOnUnwritableElement() {
        // The system-wide element does not support this attribute, so the write must fail.
        let element = SIAccessibilityElement(axElement: AXUIElementCreateSystemWide())
        XCTAssertFalse(element.setFlag(true, forKey: "AXEnhancedUserInterface" as CFString))
    }

    func testArrayForKeyReturnsNilForNonArrayAttribute() {
        // AXRole on the system-wide element is a string (when readable) or an error (when untrusted); never an array.
        let element = SIAccessibilityElement(axElement: AXUIElementCreateSystemWide())
        XCTAssertNil(element.array(forKey: kAXRoleAttribute as CFString))
    }
}
