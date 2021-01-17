//
//  AppDelegate.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/17.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(named: "statusItem_icon")
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = MainMenu()
        return statusItem
    }()
}
