//
//  Screens.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 3/29/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Foundation
import Silica

extension WindowManager {
    class Screens: Codable {
        enum CodingKeys: String, CodingKey {
            case screenManagersCache
        }

        private(set) var screenManagers: [ScreenManager<WindowManager<Application>>] = []
        private var screenManagersCache: [String: ScreenManager<WindowManager<Application>>] = [:]

        init() {}

        func updateSpaces() {
            for screenManager in screenManagers {
                guard let space = screenManager.screen?.currentSpace(), screenManager.space != space else {
                    continue
                }
                screenManager.updateSpace(to: space)
            }
        }

        func focusedScreenManager() -> ScreenManager<WindowManager<Application>>? {
            guard let focusedWindow = Window.currentlyFocused() else {
                return nil
            }
            let focusedScreenID = focusedWindow.screen()?.screenID()
            return screenManagers.first { $0.screenID == focusedScreenID }
        }

        func updateScreens(windowManager: WindowManager) {
            var screenManagers: [ScreenManager<WindowManager<Application>>] = []

            for screen in Screen.availableScreens {
                guard let screenID = screen.screenID() else {
                    continue
                }

                let screenManager = screenManagersCache[screenID] ?? ScreenManager<WindowManager<Application>>(
                    screen: screen,
                    delegate: windowManager,
                    userConfiguration: UserConfiguration.shared
                )
                screenManager.delegate = windowManager
                screenManager.updateScreen(to: screen)

                screenManagersCache[screenID] = screenManager

                screenManagers.append(screenManager)
            }

            // Window managers are sorted by screen position along the x-axis.
            // See `ScreenManager`'s `Comparable` conformance
            self.screenManagers = screenManagers.sorted()

            updateSpaces()
            markAllScreensForReflow()
        }

        func distributeEventToScreen(_ screen: Screen, change: Change<Window>, on space: Space? = nil) {
            let targetScreenID = screen.screenID()
            screenManagers
                .filter { $0.screenID == targetScreenID }
                .forEach { screenManager in
                    screenManager.distributeEvent(change, on: space)
                }
        }

        func distributeEventToAllScreens(change: Change<Window>) {
            for screenManager in screenManagers {
                screenManager.distributeEvent(change)
            }
        }

        func markScreenForReflow(_ screen: Screen, skipMainPaneRatioRecommendation: Bool = false, on space: Space? = nil) {
            let targetScreenID = screen.screenID()
            screenManagers
                .filter { $0.screenID == targetScreenID }
                .forEach { screenManager in
                    screenManager.setNeedsReflow(on: space, skipMainPaneRatioRecommendation: skipMainPaneRatioRecommendation)
                }
        }

        func markAllScreensForReflow(skipMainPaneRatioRecommendation: Bool = false, on space: Space? = nil) {
            for screenManager in screenManagers {
                screenManager.setNeedsReflow(on: space, skipMainPaneRatioRecommendation: skipMainPaneRatioRecommendation)
            }
        }
    }
}
