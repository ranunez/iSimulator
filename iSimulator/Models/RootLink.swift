//
//  RootLink.swift
//  iSimulator
//
//  Created by Peng Jin 靳朋 on 2018/12/1.
//  Copyright © 2018 niels.jin. All rights reserved.
//

import Cocoa

final class RootLink {
    private static let kUserDefaultDocumentKey = "kUserDefaultDocumentKey"
    private static let kDocumentName = "iSimulator"
    
    static private(set) var url: URL = {
        let url: URL
        if let path = UserDefaults.standard.string(forKey: kUserDefaultDocumentKey) {
            url = URL(fileURLWithPath: path)
        } else {
            url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        return url.appendingPathComponent(kDocumentName)
    }()
    
    static func createDir() {
        let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isHiddenKey], options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants])
        if let contents = contents {
            for url in contents {
                if let last = url.pathComponents.last, last == "Icon\r" {
                    try? FileManager.default.removeItem(at: self.url)
                }
            }
        }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.setIcon(#imageLiteral(resourceName: "linkDirectory"), forFile: url.path, options:[])
    }
    
    static func update(with path: String) -> String? {
        guard FileManager.default.fileExists(atPath: path) else {
            return "Folder doesn't exist!"
        }
        let linkURL = URL(fileURLWithPath: path).appendingPathComponent(kDocumentName)
        do {
            try FileManager.default.moveItem(at: url, to: linkURL)
            self.url = linkURL
            UserDefaults.standard.set(path, forKey: kUserDefaultDocumentKey)
            UserDefaults.standard.synchronize()
            return nil
        } catch {
            return error.localizedDescription
        }
    }
    
}
