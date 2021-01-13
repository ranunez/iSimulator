//
//  DeviceActionable.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/13/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Cocoa

protocol DeviceActionable {
    init(_ device: Device)
    var title: String { get }
    var icon: NSImage? { get }
    var isAvailable: Bool { get }
}

final class DeviceStateAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        switch device.state {
        case .booted:
            self.title = "Shutdown"
        case .shutdown:
            self.title = "Boot"
        }
    }
    
    @objc func perform() {
        switch device.state {
        case .booted:
            try? device.shutdown()
        case .shutdown:
            try? device.boot()
        }
    }
    
}

final class DeviceEraseAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        self.title = "Erase All content and setting..."
    }
    
    @objc func perform() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to Erase '%@'?", device.name)
        let textView = NSTextView.init(frame: NSRect(x: 0, y: 0, width: 300, height: 45))
        textView.isEditable = false
        textView.drawsBackground = false
        let prefixStr = "This action will make device reset to its initial state.\n The device udid:\n"
        let udidStr = device.udid
        let att = NSMutableAttributedString(string: prefixStr + udidStr)
        att.addAttributes([NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 11)], range: NSRange(location: prefixStr.count, length: udidStr.count))
        textView.textStorage?.append(att)
        alert.accessoryView = textView
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Erase")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        let deviceState = device.state
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            try? device.erase()
            switch deviceState{
            case .booted:
                try? device.boot()
            case .shutdown:
                try? device.shutdown()
            }
        }
    }
}

final class DeviceDeleteAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        self.title = "Delete..."
    }
    
    @objc func perform() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to delete '%@'?", device.name)
        let textView = NSTextView.init(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        textView.isEditable = false
        textView.drawsBackground = false
        let prefixStr = "All of the installed content and settings in this simulator will also be deleted.\n The device udid:\n"
        let udidStr = device.udid
        let att = NSMutableAttributedString(string: prefixStr + udidStr)
        att.addAttributes([NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 11)], range: NSRange(location: prefixStr.count, length: udidStr.count))
        textView.textStorage?.append(att)
        alert.accessoryView = textView
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            try? device.delete()
        }
    }
}
