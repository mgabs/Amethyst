import Foundation
import Cocoa

class AccessibilityPermissionCoordinator {
    static let shared = AccessibilityPermissionCoordinator()

    private init() {}

    @discardableResult
    func confirmAccessibilityPermissions(promptIfNeeded: Bool = true) -> Bool {
        let options: [String: Any] = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: promptIfNeeded
        ]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
