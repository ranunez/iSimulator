//
//  DeviceTypes.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

final class DeviceType {
    let name: String
    
    init(json: [String: Any]) {
        guard let name = json["name"] as? String else {
            fatalError()
        }
        self.name = name
    }
}
