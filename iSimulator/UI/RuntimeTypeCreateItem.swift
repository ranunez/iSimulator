//
//  RuntimeTypeCreateItem.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/13/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Cocoa

final class RuntimeTypeCreateItem: NSMenuItem {
    private let runtime: Runtime
    
    init(_ runtime: Runtime) {
        self.runtime = runtime
        super.init(title: runtime.name, action: nil, keyEquivalent: "")
        self.submenu = createDeviceItem()
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createDeviceItem() -> NSMenu {
        let menu = NSMenu()
        runtime.devicetypes.forEach {
            let item = NSMenuItem.init(title: $0.name, action: #selector(DeviceCreateAction.perform), keyEquivalent: "")
            let action = DeviceCreateAction.init(deviceType: $0, runtime: runtime)
            item.target = action
            item.representedObject = action
            menu.addItem(item)
        }
        return menu
    }
}
