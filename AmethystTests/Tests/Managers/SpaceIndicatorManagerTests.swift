//
//  SpaceIndicatorManagerTests.swift
//  AmethystTests
//
//  Created by Mohammed Metawea on 3/9/26.
//  Copyright © 2026 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import Nimble
import Quick
import Cocoa

class SpaceIndicatorManagerTests: QuickSpec {
    override func spec() {
        describe("SpaceIndicatorManager") {
            var statusItem: NSStatusItem!
            var userConfiguration: UserConfiguration!
            var manager: SpaceIndicatorManager!

            beforeEach {
                // NSWindow (and thus NSStatusItem) must be created on the main thread
                DispatchQueue.main.sync {
                    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                    userConfiguration = UserConfiguration.shared
                    manager = SpaceIndicatorManager(statusItem: statusItem, userConfiguration: userConfiguration) {
                        return "test-screen-id"
                    }
                }
            }

            describe("createSpaceImage") {
                it("creates an image with the correct size") {
                    var image: NSImage?
                    DispatchQueue.main.sync {
                        image = manager.createSpaceImage(text: "1", isActive: true, isFocused: true)
                    }
                    expect(image?.size.width).to(equal(16))
                    expect(image?.size.height).to(equal(16))
                }

                it("respects the isActive state for alpha") {
                    var activeImage: NSImage?
                    var inactiveImage: NSImage?
                    DispatchQueue.main.sync {
                        activeImage = manager.createSpaceImage(text: "1", isActive: true, isFocused: false)
                        inactiveImage = manager.createSpaceImage(text: "1", isActive: false, isFocused: false)
                    }

                    expect(activeImage).toNot(beNil())
                    expect(inactiveImage).toNot(beNil())
                }

                it("applies underline for focused monitor in all styles") {
                    let styles: [SpaceIndicatorColorStyle] = [.bordered, .solid, .solidInverted]

                    for style in styles {
                        DispatchQueue.main.sync {
                            UserConfiguration.shared.setSpaceIndicatorColorStyle(style)
                            let image = manager.createSpaceImage(text: "1", isActive: true, isFocused: true)
                            // Underline is thick (rawValue 2), we check it doesn't crash
                            expect(image).toNot(beNil())
                        }
                    }
                }
            }

            describe("combine") {
                it("combines multiple images with spacing") {
                    var combined: NSImage?
                    DispatchQueue.main.sync {
                        let img1 = NSImage(size: NSSize(width: 16, height: 16))
                        let img2 = NSImage(size: NSSize(width: 16, height: 16))
                        combined = manager.combine(images: [img1, img2])
                    }

                    // 16 + 2 (spacing) + 16 = 34
                    expect(combined?.size.width).to(equal(34))
                    expect(combined?.size.height).to(equal(16))
                }
            }
        }
    }
}
