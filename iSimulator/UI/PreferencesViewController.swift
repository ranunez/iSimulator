//
//  PreferencesViewController.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/16.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class PreferencesViewController: NSViewController {
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var pathTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pathTextField.stringValue = RootLink.url.path
    }
    
    @IBAction func changePath(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp.rawValue == NSFileHandlingPanelCancelButton {
                return
            }
            if let url = panel.url {
                self.changePathAlert(path: url.path)
            }
        }
    }
    
    @IBAction func openPath(_ sender: Any) {
        NSWorkspace.shared.open(RootLink.url)
    }
    
    private func changePathAlert(path: String) {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to change data path?")
        alert.informativeText = "The iSimulator folder will be moved to the new location."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Done")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                RootLink.update(with: path, finish: { (errorStr) in
                    if let error = errorStr {
                        self.changePathErrorAlert(error: error)
                        return
                    }
                    self.pathTextField.stringValue = RootLink.url.path
                })
            }
        }
    }
    
    private func changePathErrorAlert(error: String) {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Change data path failed!")
        alert.informativeText = error
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Done")
        NSApp.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}
