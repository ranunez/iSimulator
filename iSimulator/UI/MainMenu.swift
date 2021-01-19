//
//  BarManager.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/17.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class MainMenu: NSMenu {
    private var watchQueue: SKQueue?
    private var refreshTask: DispatchWorkItem?
    
    init() {
        super.init(title: "")
        watchQueue = SKQueue({ [weak self] (noti, _) in
            if noti.contains(.Write) && noti.contains(.SizeIncrease) {
                self?.refresh()
            }
        })
        
        refresh()
        
        self.addItem(refreshMenuItem)
        self.addItem(quitMenuItem)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func refresh() {
        refreshTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.watchQueue?.removeAllPaths()
            self.watchQueue?.addPath(Device.url.path)
            
            switch xcrun(arguments: "simctl", "list", "-j") {
            case .success(let jsonData):
                let decoder = JSONDecoder()
                var deviceItems: [NSMenuItem]
                if let runtimeList = try? decoder.decode(RuntimeList.self, from: jsonData) {
                    let runtimes = runtimeList.runtimes.sorted(by: { $0.name < $1.name })
                    
                    let allRuntimeDevices = runtimes.flatMap({ $0.devices })
                    
                    allRuntimeDevices.forEach { device in
                        self.watchQueue?.addPath(device.dataURL.path)
                        if FileManager.default.fileExists(atPath: device.bundleURL.path) {
                            self.watchQueue?.addPath(device.bundleURL.path)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        let deviceInfoURLPaths = allRuntimeDevices.compactMap({ $0.infoURL.path })
                        _ = try? FileWatch(paths: deviceInfoURLPaths, eventHandler: { [weak self] eventFlag in
                            if eventFlag.contains(.ItemIsFile) && eventFlag.contains(.ItemRenamed) {
                                self?.refresh()
                            }
                        })
                    }
                    
                    deviceItems = runtimes.flatMap { runtime -> [NSMenuItem] in
                        let hasAppDeviceItems: [NSMenuItem] = runtime.devices.filter({ !$0.applications.isEmpty }).map { DeviceMenuItem($0) }
                        if hasAppDeviceItems.isEmpty {
                            return []
                        } else {
                            let titleItem = NSMenuItem(title: runtime.name,
                                                       action: nil,
                                                       keyEquivalent: "")
                            titleItem.isEnabled = false
                            
                            var items = [NSMenuItem]()
                            items.append(titleItem)
                            items.append(contentsOf: hasAppDeviceItems)
                            return items
                        }
                    }
                    
                    if runtimes.contains(where: { $0.devices.contains(where: { $0.applications.isEmpty }) }) {
                        deviceItems.append(NSMenuItem.separator())
                    }
                } else {
                    deviceItems = []
                }
                
                deviceItems.append(self.refreshMenuItem)
                deviceItems.append(self.quitMenuItem)
                
                DispatchQueue.main.async {
                    self.removeAllItems()
                    deviceItems.forEach { self.addItem($0) }
                }
            case .failure(let error):
                error.displayAlert()
            }
        }
        self.refreshTask = task
        DispatchQueue(label: "iSimulator.update.queue").asyncAfter(deadline: .now() + 0.75, execute: task)
    }
    
    private var refreshMenuItem: NSMenuItem {
        let refreshMenuItem = NSMenuItem(title: "Refresh",
                                     action: #selector(refreshApps),
                                     keyEquivalent: "r")
        refreshMenuItem.target = self
        return refreshMenuItem
    }
    
    private var quitMenuItem: NSMenuItem {
        let quitMenu = NSMenuItem(title: "Quit",
                                  action: #selector(quitApp),
                                  keyEquivalent: "q")
        quitMenu.target = self
        return quitMenu
    }
    
    @objc private func refreshApps() {
        self.refresh()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

extension XCRunError {
    func displayAlert() {
        DispatchQueue.main.async {
            let alert: NSAlert = NSAlert()
            alert.messageText = "Error running: \(command)"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            
            alert.runModal()
        }
    }
}
