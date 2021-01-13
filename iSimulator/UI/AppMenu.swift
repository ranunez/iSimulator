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
            let item = NSMenuItem(title: action.title, action: #selector(AppShowInFinderAction.perform), keyEquivalent: "")
            item.target = action as AnyObject
            item.image = nil
            item.representedObject = action
            self.addItem(item)
        }
    }
}
