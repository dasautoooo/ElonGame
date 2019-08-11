//
//  Sound.swift
//  ElonGame
//
//  Created by Leonard Chen on 8/11/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import Foundation
import AVFoundation

enum Sound: String {
    case hit, jump, levelUp, meteorFalling, reward

    var fileName: String {
        return rawValue + "Sound.wav"
    }
}
