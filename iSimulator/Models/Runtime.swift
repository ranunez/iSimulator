//
//  Runtime.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

final class Runtime {
    let name: String
    let identifier: String
    
    var devices = [Device]()
    
    init(json: [String: Any]) {
        guard let name = json["name"] as? String else {
            fatalError()
        }
        guard let identifier = json["identifier"] as? String else {
            fatalError()
        }
        
        self.name = name
        self.identifier = identifier
    }
}
