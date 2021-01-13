//
//  Runtime.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

final class Runtime {
    enum OSType: String {
        case iOS, tvOS, watchOS, None
    }
    
    let name: String
    let identifier: String
    let osType: OSType
    
    var devices: [Device] = []
    
    var devicetypes: [DeviceType] = []
    
    init(json: [String: Any]) {
        guard let name = json["name"] as? String else {
            fatalError()
        }
        guard let identifier = json["identifier"] as? String else {
            fatalError()
        }
        
        self.name = name
        self.identifier = identifier
        
        if name.contains("iOS") {
            osType = .iOS
        } else if name.contains("tvOS") {
            osType = .tvOS
        } else if name.contains("watchOS") {
            osType = .watchOS
        } else {
            osType = .None
        }
    }
}
