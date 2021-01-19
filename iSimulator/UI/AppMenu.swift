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
    private let device: Device
    
    init(_ app: Application, device: Device) {
        self.app = app
        self.device = device
        super.init(title: "")
        
        let showAppBundleInFinderItem = NSMenuItem(title: "Show App Bundle in Finder",
                                          action: #selector(showAppBundleInFinderAction),
                                          keyEquivalent: "")
        showAppBundleInFinderItem.target = self
        showAppBundleInFinderItem.image = nil
        showAppBundleInFinderItem.representedObject = self
        self.addItem(showAppBundleInFinderItem)
        
        let showSandboxContainerInFinderItem = NSMenuItem(title: "Show Sandbox Container in Finder",
                                          action: #selector(showSandboxInFinderAction),
                                          keyEquivalent: "")
        showSandboxContainerInFinderItem.target = self
        showSandboxContainerInFinderItem.image = nil
        showSandboxContainerInFinderItem.representedObject = self
        self.addItem(showSandboxContainerInFinderItem)
        
        let launchitem = NSMenuItem(title: "Launch",
                                    action: #selector(launchAction),
                                    keyEquivalent: "")
        launchitem.target = self
        launchitem.image = nil
        launchitem.representedObject = self
        self.addItem(launchitem)
        
        let resetitem = NSMenuItem(title: "Reset Content...",
                                   action: #selector(resetAction),
                                   keyEquivalent: "")
        resetitem.target = self
        resetitem.image = nil
        resetitem.representedObject = self
        self.addItem(resetitem)
        
        if device.state == .booted {
            let terminateItem = NSMenuItem(title: "Terminate",
                                           action: #selector(terminateAction),
                                           keyEquivalent: "")
            terminateItem.target = self
            terminateItem.image = nil
            terminateItem.representedObject = self
            self.addItem(terminateItem)
            
            let uninstallItem = NSMenuItem(title: "Uninstall...",
                                           action: #selector(uninstallAction),
                                           keyEquivalent: "")
            uninstallItem.target = self
            uninstallItem.image = nil
            uninstallItem.representedObject = self
            self.addItem(uninstallItem)
        }
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func showSandboxInFinderAction() {
        let url = app.sandboxDirUrl
        NSWorkspace.shared.open(url)
    }
    
    @objc private func showAppBundleInFinderAction() {
        let url = app.bundleDirUrl
        NSWorkspace.shared.open(url)
    }
    
    @objc private func launchAction() {
        app.launch(device: device)
    }
    
    @objc private func terminateAction() {
        app.terminate(device: device)
    }
    
    @objc private func resetAction() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to Reset Content %@ from %@?", app.bundleDisplayName, device.name)
        alert.informativeText = "All of sandbox data in this application will be remove."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            app.resetContent()
        }
    }
    
    @objc private func uninstallAction() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to uninstall %@ from %@?", app.bundleDisplayName, device.name)
        alert.informativeText = "All of data(sandbox/bundle) in this application will be deleted."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            app.uninstall(device: device)
        }
    }
}
