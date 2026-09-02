//
//  Space.swift
//  Amethyst
//
//  Created by Ian Ynda-Hummel on 9/9/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Foundation
import Silica

struct Space: Equatable {
    let id: CGSSpaceID
    let type: CGSSpaceType
    let uuid: String
    let isFullscreen: Bool

    init(id: CGSSpaceID, type: CGSSpaceType, uuid: String, isFullscreen: Bool = false) {
        self.id = id
        self.type = type
        self.uuid = uuid
        self.isFullscreen = isFullscreen
    }

    init(_ space: SISpace) {
        self.init(id: space.spaceID, type: space.type, uuid: space.uuid, isFullscreen: space.isFullscreen)
    }
}
