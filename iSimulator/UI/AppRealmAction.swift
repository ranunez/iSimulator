//
//  AppRealmAction.swift
//  iSimulator
//
//  Created by Ricardo Nunez on 1/13/21.
//  Copyright © 2021 niels.jin. All rights reserved.
//

import Cocoa

final class AppRealmAction {
    var icon: NSImage? {
        return #imageLiteral(resourceName: "realmAppActionIcon")
    }
    
    let title: String
    
    private let realmPath: String
    
    init(_ title: String, path: String) {
        self.title = title
        self.realmPath = path
    }
    
    @objc func perform() {
        NSWorkspace.shared.openFile(realmPath)
    }
}
