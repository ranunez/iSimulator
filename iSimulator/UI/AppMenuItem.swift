//
//  AppMenuItem.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/24.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class AppMenuItem: NSMenuItem {
    init(_ app: Application) {
        super.init(title: "", action: nil, keyEquivalent: "")
        self.image = app.image
        self.attributedTitle = app.attributeStr
        self.indentationLevel = 1
        self.submenu = AppMenu(app)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(cowder:) has not been implemented")
    }
    
}
