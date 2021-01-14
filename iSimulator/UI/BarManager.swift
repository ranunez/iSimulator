//
//  BarManager.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/17.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class BarManager {
    static let `default` = BarManager()
    private let queue = DispatchQueue(label: "iSimulator.update.queue")
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var watch: SKQueue?
    private var refreshTask: DispatchWorkItem?
    
    private init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = #imageLiteral(resourceName: "statusItem_icon")
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = menu
        watch = SKQueue({ [weak self] (noti, _) in
            if noti.contains(.Write) && noti.contains(.SizeIncrease) {
                self?.refresh(isForceUpdate: false)
            }
        })
        
        refresh(isForceUpdate: false)
        
        self.commonItems.forEach({ (item) in
            self.menu.addItem(item)
        })
    }
    
    func refresh(isForceUpdate: Bool) {
        refreshTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.watch?.removeAllPaths()
            self.watch?.addPath(Device.url.path)
            var items: [NSMenuItem] = []
            var hasAppDeviceItemDic: [String: [NSMenuItem]] = [:]
            var emptyAppDeviceItemDic: [String: [NSMenuItem]] = [:]
            TotalModel.default.update(isForceUpdate: isForceUpdate)
            
            TotalModel.default.runtimes.forEach { r in
                var hasAppDeviceItems: [NSMenuItem] = []
                var emptyAppDeviceItems: [NSMenuItem] = []
                let devices = r.devices
                devices.forEach({ device in
                    self.watch?.addPath(device.dataURL.path)
                    if FileManager.default.fileExists(atPath: device.bundleURL.path) {
                        self.watch?.addPath(device.bundleURL.path)
                    }
                    let deviceItem = DeviceMenuItem(device)
                    if !device.applications.isEmpty {
                        hasAppDeviceItems.append(deviceItem)
                    } else{
                        emptyAppDeviceItems.append(deviceItem)
                    }
                })
                if !hasAppDeviceItems.isEmpty {
                    let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
                    titleItem.isEnabled = false
                    hasAppDeviceItems.insert(titleItem, at: 0)
                    hasAppDeviceItemDic[r.name] = hasAppDeviceItems
                }
                if !emptyAppDeviceItems.isEmpty {
                    let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
                    titleItem.isEnabled = false
                    emptyAppDeviceItems.insert(titleItem, at: 0)
                    emptyAppDeviceItemDic[r.name] = emptyAppDeviceItems
                }
            }
            let deviceInfoURLPath: [String] = TotalModel.default.runtimes.flatMap({ $0.devices }).compactMap({ $0.infoURL.path })
            DispatchQueue.main.async {
                _ = try? FileWatch(paths: deviceInfoURLPath, eventHandler: { [weak self] eventFlag in
                    if eventFlag.contains(.ItemIsFile) && eventFlag.contains(.ItemRenamed) {
                        self?.refresh(isForceUpdate: false)
                    }
                })
            }
            let sortKeys = hasAppDeviceItemDic.keys.sorted()
            for key in sortKeys {
                items.append(contentsOf: hasAppDeviceItemDic[key]!)
            }
            
            if !emptyAppDeviceItemDic.isEmpty {
                items.append(NSMenuItem.separator())
            }
            let deviceItems = items
            
            DispatchQueue.main.async {
                self.menu.removeAllItems()
                deviceItems.forEach({ item in
                    self.menu.addItem(item)
                })
                if deviceItems.isEmpty {
                    let xcodeSelectItem = NSMenuItem(title: "Xcode Select...", action: #selector(self.preference(_:)), keyEquivalent: "")
                    xcodeSelectItem.target = self
                    self.menu.addItem(xcodeSelectItem)
                }
                self.menu.addItem(NSMenuItem.separator())
                self.commonItems.forEach({ (item) in
                    self.menu.addItem(item)
                })
            }
        }
        self.refreshTask = task
        self.queue.asyncAfter(deadline: .now() + 0.75, execute: task)
    }
    
    private lazy var commonItems: [NSMenuItem] = {
        let preMenu = NSMenuItem(title: "Preferences...", action: #selector(preference(_:)), keyEquivalent: ",")
        preMenu.target = self
        
        let refreshMenu = NSMenuItem(title: "Refresh", action: #selector(refresh(_:)), keyEquivalent: "r")
        refreshMenu.target = self
        
        let quitMenu = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitMenu.target = self
        
        return [preMenu, refreshMenu, quitMenu]
    }()
    
    @objc private func refresh(_ sender: Any) {
        self.refresh(isForceUpdate: true)
    }
    
    @objc private func quitApp(_ sender: Any) {
        NSApp.terminate(nil)
    }
    
    @objc private func preference(_ sender: NSMenuItem) {
        if let existingPreferencesWindow = NSApplication.shared.windows.first(where: { $0.contentViewController is PreferencesViewController }) {
            existingPreferencesWindow.close()
        }
        
        let preferenceWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Preferences") as? NSWindowController
        NSApp.activate(ignoringOtherApps: true)
        preferenceWindowController?.window?.makeKeyAndOrderFront(NSApplication.shared)
    }
}
