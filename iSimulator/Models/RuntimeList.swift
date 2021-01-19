//
//  DeviceList.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/18/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Foundation

struct RuntimeList: Decodable {
    let runtimes: [Runtime]
    
    private enum CodingKeys: CodingKey {
        case runtimes
        case devices
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let runtimes = try container.decode([RuntimeMetadata].self, forKey: .runtimes)
        let devices = try container.decode([String: [Device]].self, forKey: .devices)
        
        self.runtimes = runtimes.map({ runtimeMetadata -> Runtime in
            let runtimeDevices = devices[runtimeMetadata.name] ?? devices[runtimeMetadata.identifier] ?? []
            return Runtime(metadata: runtimeMetadata, devices: runtimeDevices)
        }).sorted(by: { $0.name < $1.name })
    }
}
