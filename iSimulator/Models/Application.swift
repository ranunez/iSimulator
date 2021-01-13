//
//  Application.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

final class Application {
    let bundleID: String
    let bundleDirUrl: URL
    let sandboxDirUrl: URL
    let appUrl: URL
    let bundleDisplayName: String
    let bundleShortVersion: String
    let bundleVersion: String
    let image: NSImage
    private let originImage: NSImage
    weak var device: Device!
    private(set) var linkURL: URL?
    
    lazy private(set) var attributeStr: NSMutableAttributedString = {
        let name = "\(self.bundleDisplayName) - \(self.bundleShortVersion)(\(self.bundleVersion))"
        let other = "\n\(self.bundleID)"
        let att = NSMutableAttributedString(string: name + other)
        att.addAttributes([NSAttributedString.Key.font: NSFont.systemFont(ofSize: 13)], range: NSRange(location: 0, length: name.count))
        att.addAttributes([NSAttributedString.Key.font: NSFont.systemFont(ofSize: 11), NSAttributedString.Key.foregroundColor: NSColor.lightGray], range: NSRange(location: name.count, length: other.count))
        return att
    }()
    
    init?(bundleID: String, bundleDirUrl: URL, sandboxDirUrl: URL) {
        self.bundleID = bundleID
        self.bundleDirUrl = bundleDirUrl
        self.sandboxDirUrl = sandboxDirUrl
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: bundleDirUrl, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
            else {
                return nil
        }
        
        var appURLTemp: URL?
        for url in contents{
            if url.pathExtension == "app" {
                appURLTemp = url
                break
            }
        }
        guard let appURL = appURLTemp else { return nil }
        self.appUrl = appURL
        
        let appInfoURL = appURL.appendingPathComponent("Info.plist")
        guard let appInfoDict = NSDictionary(contentsOf: appInfoURL),
            let aBundleID = appInfoDict["CFBundleIdentifier"] as? String,
            let aBundleDisplayName = (appInfoDict["CFBundleDisplayName"] as? String) ?? (appInfoDict["CFBundleName"] as? String),
            aBundleID == bundleID else {
                return nil
        }
        bundleDisplayName = aBundleDisplayName
        
        let aBundleShortVersion = appInfoDict["CFBundleShortVersionString"] as? String ?? "NULL"
        let aBundleVersion = appInfoDict["CFBundleVersion"] as? String ?? "NULL"
        bundleShortVersion = aBundleShortVersion
        bundleVersion = aBundleVersion
        
        var iconFiles = ((appInfoDict["CFBundleIcons"] as? NSDictionary)?["CFBundlePrimaryIcon"] as? NSDictionary)?["CFBundleIconFiles"] as? [String]
        if iconFiles == nil {
            iconFiles = ["Icon.png"]
        }
        if let imageStr = iconFiles?.last,
            let bundle = Bundle(url: appUrl),
            let im = bundle.image(forResource: imageStr) {
            originImage = im
            image = im.appIcon()
        } else {
            originImage = #imageLiteral(resourceName: "default_ios_app_icon").appIcon(h: 512)
            
            image = #imageLiteral(resourceName: "default_ios_app_icon").appIcon()
        }
    }
    
    func launch() {
        if device.state == .shutdown {
            try? device.boot()
        }
        shell("/usr/bin/xcrun", arguments: "simctl", "launch", device.udid, bundleID)
    }
    
    func terminate() {
        shell("/usr/bin/xcrun", arguments: "simctl", "terminate", device.udid, bundleID)
    }
    
    func uninstall() {
        self.terminate()
        shell("/usr/bin/xcrun", arguments: "simctl", "uninstall", device.udid, bundleID)
    }
    
    func resetContent() {
        let contents = try? FileManager.default.contentsOfDirectory(at: sandboxDirUrl, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        contents?.forEach({ (url) in
            try? FileManager.default.removeItem(at: url)
        })
    }
    
    func createLinkDir() {
        guard self.linkURL == nil else {
            return
        }
        var url = RootLink.url
        url.appendPathComponent(self.device.runtime.name)
        let duplicateDeviceNames = self.device.runtime.devices.map{$0.name}.divideDuplicates().duplicates
        if duplicateDeviceNames.contains(self.device.name) {
            url.appendPathComponent("\(self.device.name)_\(self.device.udid)")
        }else{
            url.appendPathComponent(device.name)
        }
        let duplicateAppNames = device.applications.map{$0.bundleDisplayName}.divideDuplicates().duplicates
        if duplicateAppNames.contains(self.bundleDisplayName) {
            url.appendPathComponent("\(self.bundleDisplayName)_\(self.bundleID)")
        } else {
            url.appendPathComponent(self.bundleDisplayName)
        }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            self.linkURL = url
        } catch {
            return
        }
        let bundleURL = url.appendingPathComponent("Bundle")
        let sandboxURL = url.appendingPathComponent("Sandbox")
        createSymbolicLink(at: bundleURL, withDestinationURL: self.bundleDirUrl)
        createSymbolicLink(at: sandboxURL, withDestinationURL: self.sandboxDirUrl)
        
        NSWorkspace.shared.setIcon(self.originImage, forFile: url.path, options:[])
    }
    
    private func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) {
        if let destinationUrlPath = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path),
            destinationUrlPath == destURL.path{
            return
        }
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createSymbolicLink(at: url, withDestinationURL: destURL)
    }
    
    func removeLinkDir() {
        guard let url = self.linkURL else {
            return
        }
        let bundleURL = url.appendingPathComponent("Bundle")
        if let destinationUrlPath = try? FileManager.default.destinationOfSymbolicLink(atPath: bundleURL.path),
            FileManager.default.fileExists(atPath: destinationUrlPath){
            return
        }
        try? FileManager.default.removeItem(at: url)
    }
}

extension NSImage {
    fileprivate func appIcon(h:CGFloat = 35) -> NSImage {
        let size = NSSize(width: h, height: h)
        let cornerRadius: CGFloat = h/5
        guard self.isValid else {
            return self
        }
        let newImage = NSImage(size: size)

        self.size = size
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSGraphicsContext.saveGraphicsState()
        let path = NSBezierPath(roundedRect: NSRect(origin: NSPoint.zero, size: size), xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()
        self.draw(at: NSPoint.zero, from: NSRect(origin: NSPoint.zero, size: size), operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        newImage.unlockFocus()
        return newImage
    }
}
