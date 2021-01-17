//
//  BarManager.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/17.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class BarManager {
    private let queue = DispatchQueue(label: "iSimulator.update.queue")
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var lastXcodePath = ""
    private var appCache = ApplicationCache()
    private var runtimes: [Runtime] = []
    private var watchQueue: SKQueue?
    private var refreshTask: DispatchWorkItem?
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = #imageLiteral(resourceName: "statusItem_icon")
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = menu
        watchQueue = SKQueue({ [weak self] (noti, _) in
            if noti.contains(.Write) && noti.contains(.SizeIncrease) {
                self?.refresh(isForceUpdate: false)
            }
        })
        
        refresh(isForceUpdate: false)
        
        self.commonItems.forEach({ (item) in
            self.menu.addItem(item)
        })
    }
    
    private func refresh(isForceUpdate: Bool) {
        refreshTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.watchQueue?.removeAllPaths()
            self.watchQueue?.addPath(Device.url.path)
            
            let xcodePathData = xcrun(arguments: "xcode-select", "-p")
            
            let shouldUpdateCache: Bool
            if let xcodePath = String(data: xcodePathData, encoding: .utf8), self.lastXcodePath != xcodePath {
                self.lastXcodePath = xcodePath
                shouldUpdateCache = true
            } else if isForceUpdate {
                shouldUpdateCache = true
            } else {
                shouldUpdateCache = false
            }
            
            if shouldUpdateCache {
                self.appCache = ApplicationCache()
                DispatchQueue.main.async {
                    let rootLinkURL = UserDefaults.standard.rootLinkURL
                    let contents = try? FileManager.default.contentsOfDirectory(at: rootLinkURL,
                                                                                includingPropertiesForKeys: [.isHiddenKey],
                                                                                options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants])
                    contents?.filter({ $0.pathComponents.last == "Icon\r" }).forEach({ _ in try? FileManager.default.removeItem(at: rootLinkURL) })
                    try? FileManager.default.createDirectory(at: rootLinkURL, withIntermediateDirectories: true)
                    NSWorkspace.shared.setIcon(#imageLiteral(resourceName: "statusItem_icon"), forFile: rootLinkURL.path, options:[])
                }
            }
            
            let jsonData = xcrun(arguments: "simctl", "list", "-j")
            guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
                fatalError()
            }
            
            if let rawRunTimes = json["runtimes"] as? [[String: Any]], let rawDevices = json["devices"] as? [String: [[String: Any]]] {
                self.runtimes = rawRunTimes.map({ iSimulator.Runtime(json: $0) })
                
                let devices = rawDevices.reduce([String: [Device]]()) { (result, rawDevice) -> [String: [Device]] in
                    var updatedResult = result
                    updatedResult[rawDevice.key] = rawDevice.value.map({ iSimulator.Device(json: $0) })
                    return updatedResult
                }
                
                var urlAndAppDicCache = [URL: Application]()
                var sandboxURLsCache = Set<URL>()
                self.runtimes.forEach { runtime in
                    runtime.devices = devices[runtime.name] ?? devices[runtime.identifier] ?? []
                    
                    runtime.devices.forEach {
                        $0.runtime = runtime
                        $0.updateApps(with: self.appCache)
                        $0.updateAppGroups()
                        
                        $0.applications.forEach { app in
                            app.removeLinkDir()
                            urlAndAppDicCache[app.bundleDirUrl] = app
                            sandboxURLsCache.insert(app.sandboxDirUrl)
                        }
                    }
                }
                
                self.appCache.urlAndAppDic = urlAndAppDicCache
                self.appCache.sandboxURLs = sandboxURLsCache
                
                self.runtimes.forEach { runtime in
                    runtime.devices.forEach { device in
                        self.watchQueue?.addPath(device.dataURL.path)
                        if FileManager.default.fileExists(atPath: device.bundleURL.path) {
                            self.watchQueue?.addPath(device.bundleURL.path)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    let deviceInfoURLPaths = self.runtimes.flatMap({ $0.devices }).compactMap({ $0.infoURL.path })
                    _ = try? FileWatch(paths: deviceInfoURLPaths, eventHandler: { [weak self] eventFlag in
                        if eventFlag.contains(.ItemIsFile) && eventFlag.contains(.ItemRenamed) {
                            self?.refresh(isForceUpdate: false)
                        }
                    })
                }
            } else {
                self.runtimes = []
                self.appCache.urlAndAppDic = [:]
                self.appCache.sandboxURLs = []
            }
            
            var deviceItems = self.runtimes.sorted(by: { $0.name < $1.name }).flatMap { runtime -> [NSMenuItem] in
                let hasAppDeviceItems: [NSMenuItem] = runtime.devices.filter({ !$0.applications.isEmpty }).compactMap { DeviceMenuItem($0) }
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
            
            if self.runtimes.contains(where: { $0.devices.contains(where: { $0.applications.isEmpty }) }) {
                deviceItems.append(NSMenuItem.separator())
            }
            
            if deviceItems.isEmpty {
                let xcodeSelectItem = NSMenuItem(title: "Xcode Select...",
                                                 action: #selector(self.openPreferences),
                                                 keyEquivalent: "")
                xcodeSelectItem.target = self
                deviceItems.append(xcodeSelectItem)
            }
            
            deviceItems.append(NSMenuItem.separator())
            deviceItems.append(contentsOf: self.commonItems)
            
            DispatchQueue.main.async {
                self.menu.removeAllItems()
                deviceItems.forEach { self.menu.addItem($0) }
            }
        }
        self.refreshTask = task
        self.queue.asyncAfter(deadline: .now() + 0.75, execute: task)
    }
    
    private lazy var commonItems: [NSMenuItem] = {
        let preMenu = NSMenuItem(title: "Preferences...",
                                 action: #selector(openPreferences),
                                 keyEquivalent: ",")
        preMenu.target = self
        
        let refreshMenu = NSMenuItem(title: "Refresh",
                                     action: #selector(refreshApps),
                                     keyEquivalent: "r")
        refreshMenu.target = self
        
        let quitMenu = NSMenuItem(title: "Quit",
                                  action: #selector(quitApp),
                                  keyEquivalent: "q")
        quitMenu.target = self
        
        return [preMenu, refreshMenu, quitMenu]
    }()
    
    @objc private func refreshApps() {
        self.refresh(isForceUpdate: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc private func openPreferences() {
        if let existingPreferencesWindow = NSApplication.shared.windows.first(where: { $0.contentViewController is PreferencesViewController }) {
            existingPreferencesWindow.close()
        }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let preferenceWindowController = storyboard.instantiateController(withIdentifier: "Preferences") as? NSWindowController
        NSApp.activate(ignoringOtherApps: true)
        preferenceWindowController?.window?.makeKeyAndOrderFront(NSApplication.shared)
    }
}
