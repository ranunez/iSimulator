//
//  Runtime.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

struct RuntimeMetadata: Decodable {
    let name: String
    let identifier: String
}

struct Runtime: Decodable {
    let name: String
    let identifier: String
    let devices: [Device]
    
    init(name: String, identifier: String, devices: [Device]) {
        self.name = name
        self.identifier = identifier
        self.devices = devices
    }
    
    init(metadata: RuntimeMetadata, devices: [Device]) {
        self.init(name: metadata.name,
                  identifier: metadata.identifier,
                  devices: devices)
    }
}
