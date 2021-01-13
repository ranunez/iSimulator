//
//  DeviceTypeCreateItem.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/13/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Cocoa

final class DeviceTypeCreateItem: NSMenuItem {
    init() {
        super.init(title: "Create New Simulator", action: nil, keyEquivalent: "")
        let menu = NSMenu()
        TotalModel.default.runtimes.forEach { (r) in
            let item = RuntimeTypeCreateItem.init(r)
            menu.addItem(item)
        }
        self.submenu = menu
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
