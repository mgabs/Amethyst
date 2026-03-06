//
//  FrameAssignmentVerification.swift
//  AmethystTests
//
//  Created by Ian Ynda-Hummel on 9/21/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

@testable import Amethyst
import Foundation
import Nimble

extension RandomAccessCollection where Element == FrameAssignment<TestWindow>, Index == Int {
    func filtered(byIDs ids: [TestWindow.WindowID]) -> [Element] {
        return filter { ids.contains($0.window.id) }
    }

    func forWindows<C: RandomAccessCollection>(_ windows: C) -> [Element] where C.Element == TestWindow, C.Index == Index {
        return filtered(byIDs: Array(windows).map { $0.id() })
    }

    func sorted() -> [Element] {
        return sorted { $0.frame.origin.x < $1.frame.origin.x }
            .sorted { $0.frame.origin.y < $1.frame.origin.y }
    }

    func frames() -> [CGRect] {
        return map { $0.frame }
    }

    func description(withExpectedFrames frames: [CGRect]) -> String {
        return zip(self, frames).map { assignment, frame in
            return "\(assignment.window.id):\n\tFrame: \(assignment.frame)\n\tExpected: \(frame)"
        }.joined(separator: "\n")
    }

    func verify(frames: [CGRect], inOrder: Bool = false) {
        expect(self.count).to(equal(frames.count), description: "\(count) assignments, but \(frames.count) frames")

        if inOrder {
            zip(self, frames).forEach { assignment, frame in
                expect(assignment.frame).to(equal(frame))
            }
        } else {
            let currentFrames = map { $0.frame }
            for frame in frames {
                expect(currentFrames).to(contain(frame))
            }
        }
    }

    func verify(frames: [String: CGRect]) {
        var unverifiedFrames = frames
        for assignment in self {
            let id = assignment.window.id
            expect(unverifiedFrames[id]).toNot(beNil(), description: "\(id) should exist")
            expect(assignment.frame).to(equal(unverifiedFrames[id]), description: "\(id)")
            unverifiedFrames[id] = nil
        }
        expect(unverifiedFrames).to(beEmpty())
    }
}
