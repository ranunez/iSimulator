//
//  DeviceList.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/18/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Foundation

struct DeviceList: Decodable {
    let runtimes: [Runtime]
    let devices: [String: [Device]]
}
