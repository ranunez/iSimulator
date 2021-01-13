//
//  DevcieMenuItem.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/10.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class DeviceMenuItem: NSMenuItem {
    let isEmptyApp: Bool
    
    init(_ device: Device) {
        isEmptyApp = !device.applications.isEmpty
        super.init(title: device.name, action: nil, keyEquivalent: "")
        self.onStateImage = NSImage.init(named: NSImage.statusAvailableName)
        self.offStateImage = nil
        self.state = device.state == .shutdown ? .off : .on
        self.submenu = NSMenu()
        if !device.applications.isEmpty {
            self.submenu?.addItem(NSMenuItem.init(title: "Application", action: nil, keyEquivalent: ""))
            device.applications.forEach({ (app) in
                self.submenu?.addItem(AppMenuItem(app))
            })
            self.submenu?.addItem(NSMenuItem.separator())
        }
        let deviceActionItems = createDeviceActionItems(device)
        deviceActionItems.forEach({ (item) in
            self.submenu?.addItem(item)
        })
        if !device.pairs.isEmpty{
            self.submenu?.addItem(NSMenuItem.separator())
            pairActionItems(device).forEach({ (item) in
                self.submenu?.addItem(item)
            })
        }
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(cowder:) has not been implemented")
    }
    
    private func pairActionItems(_ device: Device) -> [NSMenuItem] {
        var items: [NSMenuItem] = []
        let item = NSMenuItem(title: "Paired Watches", action: nil, keyEquivalent: "")
        item.isEnabled = false
        items.append(item)
        device.pairs.forEach {
            let item = DeviceMenuItem.init($0)
            item.indentationLevel = 1
            items.append(item)
        }
        return items
    }
    
    private func createDeviceActionItems(_ device: Device) -> [NSMenuItem] {
        let actionTypes: [DeviceActionable.Type] = [DeviceStateAction.self,
                                                    DeviceEraseAction.self,
                                                    DeviceDeleteAction.self]
        let actions = actionTypes.map { $0.init(device) }.filter { $0.isAvailable  }
        var items = actions.map { (action) -> NSMenuItem in
            let item = NSMenuItem.init(title: action.title, action: #selector(DeviceStateAction.perform), keyEquivalent: "")
            item.indentationLevel = 1
            item.target = action as AnyObject
            item.image = action.icon
            item.representedObject = action
            return item
        }
        items.insert(NSMenuItem.init(title: "Simulator Action", action: nil, keyEquivalent: ""), at: 0)
        return items
    }
}
