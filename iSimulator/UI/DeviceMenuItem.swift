//
//  DevcieMenuItem.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/10.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class DeviceMenuItem: NSMenuItem {
    private let device: Device
    
    init(_ device: Device) {
        self.device = device
        super.init(title: device.name, action: nil, keyEquivalent: "")
        self.onStateImage = NSImage(named: NSImage.statusAvailableName)
        self.offStateImage = nil
        self.state = device.state == .shutdown ? .off : .on
        self.submenu = NSMenu()
        
        if !device.applications.isEmpty {
            self.submenu?.addItem(NSMenuItem(title: "Application",
                                             action: nil,
                                             keyEquivalent: ""))
            device.applications.forEach({ app in
                
                let appMenuItem = NSMenuItem(title: "",
                                             action: nil,
                                             keyEquivalent: "")
                appMenuItem.image = app.image
                
                let name = "\(app.bundleDisplayName) - \(app.bundleShortVersion)(\(app.bundleVersion))"
                let other = "\n\(app.bundleID)"
                let attributedString = NSMutableAttributedString(string: name + other)
                
                attributedString.addAttributes([.font: NSFont.systemFont(ofSize: 13)],
                                               range: NSRange(location: 0,
                                                              length: name.count))
                
                attributedString.addAttributes([.font: NSFont.systemFont(ofSize: 11),
                                                .foregroundColor: NSColor.lightGray],
                                               range: NSRange(location: name.count,
                                                              length: other.count))
                
                appMenuItem.attributedTitle = attributedString
                appMenuItem.indentationLevel = 1
                appMenuItem.submenu = AppMenu(app, device: device)
                
                self.submenu?.addItem(appMenuItem)
            })
            self.submenu?.addItem(NSMenuItem.separator())
        }
        
        let simActionItem = NSMenuItem(title: "Simulator Action",
                                       action: nil,
                                       keyEquivalent: "")
        self.submenu?.addItem(simActionItem)
        
        let stateItemTitle: String
        switch device.state {
        case .booted:
            stateItemTitle = "Shutdown"
        case .shutdown:
            stateItemTitle = "Boot"
        }
        
        let stateitem = NSMenuItem(title: stateItemTitle,
                                   action: #selector(performStateAction),
                                   keyEquivalent: "")
        stateitem.indentationLevel = 1
        stateitem.target = self
        stateitem.image = nil
        stateitem.representedObject = action
        self.submenu?.addItem(stateitem)
        
        let eraseitem = NSMenuItem(title: "Erase All content and setting...",
                                   action: #selector(performEraseAction),
                                   keyEquivalent: "")
        eraseitem.indentationLevel = 1
        eraseitem.target = self
        eraseitem.image = nil
        eraseitem.representedObject = action
        self.submenu?.addItem(eraseitem)
        
        let deleteitem = NSMenuItem(title: "Delete...",
                                    action: #selector(performDeleteAction),
                                    keyEquivalent: "")
        deleteitem.indentationLevel = 1
        deleteitem.target = self
        deleteitem.image = nil
        deleteitem.representedObject = action
        self.submenu?.addItem(deleteitem)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(cowder:) has not been implemented")
    }
    
    @objc private func performStateAction() {
        switch device.state {
        case .booted:
            switch device.shutdown() {
            case .success:
                break
            case .failure(let error):
                error.displayAlert()
            }
        case .shutdown:
            switch device.boot() {
            case .success:
                break
            case .failure(let error):
                error.displayAlert()
            }
        }
    }
    
    @objc private func performEraseAction() {
        let alert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to Erase '%@'?", device.name)
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 45))
        textView.isEditable = false
        textView.drawsBackground = false
        let prefixStr = "This action will make device reset to its initial state.\n The device udid:\n"
        let udidStr = device.udid.uuidString
        let att = NSMutableAttributedString(string: prefixStr + udidStr)
        att.addAttributes([.font: NSFont.boldSystemFont(ofSize: 11)],
                          range: NSRange(location: prefixStr.count,
                                         length: udidStr.count))
        textView.textStorage?.append(att)
        alert.accessoryView = textView
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Erase")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        let deviceState = device.state
        if response == .alertFirstButtonReturn {
            switch device.erase() {
            case .success:
                switch deviceState{
                case .booted:
                    switch device.boot() {
                    case .success:
                        break
                    case .failure(let error):
                        error.displayAlert()
                    }
                case .shutdown:
                    switch device.shutdown() {
                    case .success:
                        break
                    case .failure(let error):
                        error.displayAlert()
                    }
                }
            case .failure(let error):
                error.displayAlert()
            }
        }
    }
    
    @objc private func performDeleteAction() {
        let alert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to delete '%@'?", device.name)
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        textView.isEditable = false
        textView.drawsBackground = false
        let prefixStr = "All of the installed content and settings in this simulator will also be deleted.\n The device udid:\n"
        let udidStr = device.udid.uuidString
        let att = NSMutableAttributedString(string: prefixStr + udidStr)
        att.addAttributes([.font: NSFont.boldSystemFont(ofSize: 11)],
                          range: NSRange(location: prefixStr.count,
                                         length: udidStr.count))
        textView.textStorage?.append(att)
        alert.accessoryView = textView
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            switch device.delete() {
            case .success:
                break
            case .failure(let error):
                error.displayAlert()
            }
        }
    }
}
