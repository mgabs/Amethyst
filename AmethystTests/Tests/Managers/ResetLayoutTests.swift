
@testable import Amethyst
import Nimble
import Quick
import Silica

private final class TestDelegate: ScreenManagerDelegate {
    typealias Window = TestWindow

    func applyWindowLimit(forScreenManager screenManager: ScreenManager<TestDelegate>, minimizingIn range: (Int) -> Range<Int>) {}
    func activeWindowSet(forScreenManager screenManager: ScreenManager<TestDelegate>) -> WindowSet<TestWindow> {
        return WindowSet(windows: [], activeWindows: [], mainWindows: [])
    }
    func onReflowInitiation() {}
    func onReflowCompletion() {}
}

class ResetLayoutTests: QuickSpec {
    override func spec() {
        describe("resetLayout") {
            var configuration: UserConfiguration!
            var screenManager: ScreenManager<TestDelegate>!
            var screen: TestScreen!

            beforeEach {
                configuration = UserConfiguration(storage: TestConfigurationStorage())
                configuration.setLayoutKeys([TallLayout<TestWindow>.layoutKey])
                screen = TestScreen()
                screenManager = ScreenManager(screen: screen, delegate: TestDelegate(), userConfiguration: configuration)
            }

            it("resets the current layout proportions") {
                let layout = screenManager.currentLayout as? TallLayout<TestWindow>
                expect(layout).toNot(beNil())
                expect(layout?.mainPaneRatio).to(equal(0.5))

                // Change ratio
                layout?.recommendMainPaneRatio(0.8)
                expect(layout?.mainPaneRatio).to(equal(0.8))

                // Reset
                screenManager.resetLayout()

                let resetLayout = screenManager.currentLayout as? TallLayout<TestWindow>
                expect(resetLayout?.mainPaneRatio).to(equal(0.5))
            }

            it("resets layout for a specific space") {
                let space = Space(id: 1, type: .user, uuid: "test-space-uuid")
                screenManager.updateSpace(to: space)

                let layout = screenManager.currentLayout as? TallLayout<TestWindow>
                layout?.recommendMainPaneRatio(0.2)
                expect(layout?.mainPaneRatio).to(equal(0.2))

                // Reset specifically for this space
                screenManager.resetLayout(for: space)

                let resetLayout = screenManager.currentLayout as? TallLayout<TestWindow>
                expect(resetLayout?.mainPaneRatio).to(equal(0.5))
            }
        }
    }
}
