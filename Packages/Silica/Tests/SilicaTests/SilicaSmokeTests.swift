import Silica
import XCTest

final class SilicaSmokeTests: XCTestCase {
    func testModuleExposesCoreTypes() {
        // Link-and-run smoke test only: no Accessibility trust on CI, so no AX results are asserted here.
        let element = SIAccessibilityElement(axElement: AXUIElementCreateSystemWide())
        _ = element.processIdentifier()
        XCTAssertEqual(CGSSpaceTypeUser.rawValue, 0)
        _ = NSScreen.main?.frameIncludingDockAndMenu()
    }
}
