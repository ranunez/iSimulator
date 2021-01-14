//
//  Pair.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/15.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

struct Pair {
    let watch: Device?
    let phone: Device?
    
    init(json: [String: Any]) {
        guard let rawWatch = json["watch"] as? [String: Any] else {
            fatalError()
        }
        let watch = iSimulator.Device(json: rawWatch)
        
        guard let rawPhone = json["phone"] as? [String: Any] else {
            fatalError()
        }
        let phone = iSimulator.Device(json: rawPhone)
        
        self.watch = watch
        self.phone = phone
    }
}
