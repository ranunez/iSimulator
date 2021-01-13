//
//  AppActionable.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/13/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Cocoa

protocol AppActionable {
    init(_ app: Application)
    var title: String { get }
    var icon: NSImage? { get }
    var isAvailable: Bool { get }
}

final class AppShowInFinderAction: AppActionable {
    private let app: Application
    
    let title: String = "Show in Finder"
    
    let isAvailable: Bool = true
    
    var icon: NSImage?
    
    required init(_ app: Application) {
        self.app = app
    }
    
    @objc func perform() {
        if let url = app.linkURL {
            NSWorkspace.shared.open(url)
        }
    }
}

final class DeviceLaunchOtherAppAction: AppActionable {
    private let app: Application
    let device: Device
    let title: String
    let isAvailable: Bool = true
    var icon: NSImage?
    
    required init(app: Application, device: Device) {
        self.app = app
        self.device = device
        self.title = device.name
    }
    
    required init(_ app: Application) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func perform() {
        device.installApp(app)
        device.launch(appBundleId: app.bundleID)
    }
}

final class AppLaunchAction: AppActionable {
    private let app: Application
    
    let title: String = "Launch"
    
    let isAvailable: Bool = true
    
    var icon: NSImage?
    
    required init(_ app: Application) {
        self.app = app
    }
    
    @objc func perform() {
        app.launch()
    }
}

final class AppTerminateAction: AppActionable {
    private let app: Application
    
    let title: String = "Terminate"
    
    var icon: NSImage?
    
    var isAvailable: Bool {
        return app.device.state == .booted
    }
    
    required init(_ app: Application) {
        self.app = app
    }
    
    @objc func perform() {
        app.terminate()
    }
}

final class AppResetAction: AppActionable {
    private let app: Application
    
    let title: String = "Reset Content..."
    
    var icon: NSImage?
    
    var isAvailable: Bool {
        return true
    }
    
    required init(_ app: Application) {
        self.app = app
    }
    
    @objc func perform() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to Reset Content %@ from %@?", app.bundleDisplayName, app.device.name)
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
}

final class AppUninstallAction: AppActionable {
    private let app: Application
    
    let title: String = "Uninstall..."
    
    var isAvailable: Bool {
        return app.device.state == .booted
    }
    
    var icon: NSImage?
    
    required init(_ app: Application) {
        self.app = app
    }
    
    @objc func perform() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to uninstall %@ from %@?", app.bundleDisplayName, app.device.name)
        alert.informativeText = "All of data(sandbox/bundle) in this application will be deleted."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            app.uninstall()
        }
    }
}
