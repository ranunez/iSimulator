//
//  ActionMenu.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/24.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

//  FileInfo DirectoryWatcher CancelBlocks

import Cocoa

final class AppMenu: NSMenu {

    private let app: Application
    
    init(_ app: Application) {
        self.app = app
        super.init(title: "")
        addCustomItem()
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addCustomItem() {
        let actionTypes: [AppActionable.Type] = [AppShowInFinderAction.self,
                                                 AppLaunchAction.self,
                                                 AppResetAction.self,
                                                 AppTerminateAction.self,
                                                 AppUninstallAction.self]
        actionTypes.forEach { (ActionType) in
            let action = ActionType.init(app)
            if !action.isAvailable {
                return
            }
            let item = NSMenuItem.init(title: action.title, action: #selector(AppShowInFinderAction.perform), keyEquivalent: "")
            item.target = action as AnyObject
            item.image = action.icon
            item.representedObject = action
            self.addItem(item)
        }
        self.insertItem(createOtherSimLunchAppItem(), at: 2)
        if let item = createRealmAppItem() {
            self.insertItem(item, at: 3)
        }
    }
    
    func createOtherSimLunchAppItem() -> NSMenuItem {
        let otherSimLunchAppItem = NSMenuItem.init(title: "Launch From Other Simulator", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let runtimes: [Runtime] = TotalModel.default.runtimes(osType: app.device.runtime.osType)
        var appDeviceItemDic: [String: [NSMenuItem]] = [:]
        runtimes.forEach { (r) in
            var appDeviceItems: [NSMenuItem] = []
            r.devices.forEach({ (device) in
                if device === app.device {
                    return
                }
                let action = DeviceLaunchOtherAppAction.init(app: app, device: device)
                let item = NSMenuItem.init(title: device.name, action: #selector(action.perform), keyEquivalent: "")
                item.target = action as AnyObject
                item.representedObject = action
                appDeviceItems.append(item)
            })
            if !appDeviceItems.isEmpty {
                let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
                titleItem.isEnabled = false
                appDeviceItems.insert(titleItem, at: 0)
                appDeviceItemDic[r.name] = appDeviceItems
            }
        }
        appDeviceItemDic.forEach { (_, deviceItems) in
            deviceItems.forEach({ (item) in
                submenu.addItem(item)
            })
        }
        otherSimLunchAppItem.submenu = submenu
        return otherSimLunchAppItem
    }
    
    func createRealmAppItem() -> NSMenuItem? {
        let all = FileManager.default.enumerator(at: app.sandboxDirUrl, includingPropertiesForKeys: nil)
        var realmFilePaths: [String] = []
        while let fileUrl = all?.nextObject() as? URL {
            if fileUrl.pathExtension.lowercased() == "realm" {
                realmFilePaths.append(fileUrl.path)
            }
        }
        guard !realmFilePaths.isEmpty else {
            return nil
        }
        if realmFilePaths.count == 1 {
            let action = AppRealmAction.init("Open Realm Database", path: realmFilePaths[0])
            let item = NSMenuItem.init(title: action.title, action: #selector(action.perform), keyEquivalent: "")
            item.target = action as AnyObject
            item.image = action.icon
            item.representedObject = action
            return item
        } else {
            let item = NSMenuItem.init(title: "Open Realm Database", action: nil, keyEquivalent: "")
            item.image = #imageLiteral(resourceName: "realmAppActionIcon")
            let submenu = NSMenu()
            realmFilePaths.forEach { (path) in
                let action = AppRealmAction.init(URL.init(fileURLWithPath: path).lastPathComponent, path: path)
                let item = NSMenuItem.init(title: action.title, action: #selector(action.perform), keyEquivalent: "")
                item.target = action as AnyObject
                item.representedObject = action
                submenu.addItem(item)
            }
            item.submenu = submenu
            return item
        }
    }
}
