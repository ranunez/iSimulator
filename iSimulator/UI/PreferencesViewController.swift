//
//  PreferencesViewController.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/16.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class PreferencesViewController: NSViewController {
    @IBOutlet private weak var pathTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pathTextField.stringValue = UserDefaults.standard.rootLinkURL.path
    }
    
    @IBAction private func changePath(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            guard resp != .cancel else { return }
            guard let url = panel.url else { return }
            self.changePathAlert(updatedURL: url)
        }
    }
    
    @IBAction private func openPath(_ sender: Any) {
        NSWorkspace.shared.open(UserDefaults.standard.rootLinkURL)
    }
    
    private func changePathAlert(updatedURL: URL) {
        let alert: NSAlert = NSAlert()
        alert.messageText = "Are you sure you want to change data path?"
        alert.informativeText = "The iSimulator folder will be moved to the new location."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Done")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!) { response in
            guard response == .alertFirstButtonReturn else { return }
            do {
                guard FileManager.default.fileExists(atPath: updatedURL.path) else {
                    throw URLError(.fileDoesNotExist)
                }
                let linkURL = updatedURL.appendingPathComponent(UserDefaults.kDocumentName)
                try FileManager.default.moveItem(at: UserDefaults.standard.rootLinkURL, to: linkURL)
                UserDefaults.standard.set(updatedURL.path, forKey: UserDefaults.kUserDefaultDocumentKey)
                UserDefaults.standard.synchronize()
                self.pathTextField.stringValue = updatedURL.path
            } catch let error {
                self.changePathErrorAlert(error: error.localizedDescription)
            }
        }
    }
    
    private func changePathErrorAlert(error: String) {
        let alert: NSAlert = NSAlert()
        alert.messageText = "Change data path failed!"
        alert.informativeText = error
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Done")
        NSApp.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}
