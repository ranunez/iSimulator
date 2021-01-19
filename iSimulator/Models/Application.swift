//
//  Application.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

struct Application {
    let bundleID: String
    let bundleDirUrl: URL
    let sandboxDirUrl: URL
    let bundleDisplayName: String
    let bundleShortVersion: String
    let bundleVersion: String
    let image: NSImage
    
    init?(bundleID: String, bundleDirUrl: URL, sandboxDirUrl: URL) {
        self.bundleID = bundleID
        self.bundleDirUrl = bundleDirUrl
        self.sandboxDirUrl = sandboxDirUrl
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: bundleDirUrl,
                                                                          includingPropertiesForKeys: nil,
                                                                          options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else {
            return nil
        }
        
        guard let appURL = contents.first(where: { $0.pathExtension == "app" }) else { return nil }
        
        let appInfoURL = appURL.appendingPathComponent("Info.plist")
        guard let appInfoDict = NSDictionary(contentsOf: appInfoURL),
            let aBundleID = appInfoDict["CFBundleIdentifier"] as? String,
            let aBundleDisplayName = (appInfoDict["CFBundleDisplayName"] as? String) ?? (appInfoDict["CFBundleName"] as? String),
            aBundleID == bundleID else {
                return nil
        }
        bundleDisplayName = aBundleDisplayName
        bundleShortVersion = appInfoDict["CFBundleShortVersionString"] as? String ?? "NULL"
        bundleVersion = appInfoDict["CFBundleVersion"] as? String ?? "NULL"
        
        let iconFile: String?
        if let cfBundleIconsDictionary = appInfoDict["CFBundleIcons"] as? [String: Any], let cfBundlePrimaryIconDictionary = cfBundleIconsDictionary["CFBundlePrimaryIcon"] as? [String: Any], let icons = cfBundlePrimaryIconDictionary["CFBundleIconFiles"] as? [String] {
            iconFile = icons.last
        } else if let cfBundleIconsDictionary = appInfoDict["CFBundleIcons~ipad"] as? [String: Any], let cfBundlePrimaryIconDictionary = cfBundleIconsDictionary["CFBundlePrimaryIcon"] as? [String: Any], let icons = cfBundlePrimaryIconDictionary["CFBundleIconFiles"] as? [String] {
            iconFile = icons.last?.appending("@2x~ipad")
        } else {
            iconFile = "Icon.png"
        }
        
        if let iconFile = iconFile, let bundle = Bundle(url: appURL), let im = bundle.image(forResource: iconFile) {
            image = im.appIcon()
        } else {
            image = #imageLiteral(resourceName: "default_ios_app_icon_small")
        }
    }
    
    func launch(device: Device) {
        if device.state == .shutdown {
            switch device.boot() {
            case .success:
                break
            case .failure(let error):
                error.displayAlert()
            }
        }
        xcrun(arguments: "simctl", "launch", device.udid.uuidString, bundleID)
    }
    
    func terminate(device: Device) {
        xcrun(arguments: "simctl", "terminate", device.udid.uuidString, bundleID)
    }
    
    func uninstall(device: Device) {
        self.terminate(device: device)
        xcrun(arguments: "simctl", "uninstall", device.udid.uuidString, bundleID)
    }
    
    func resetContent() {
        let contents = try? FileManager.default.contentsOfDirectory(at: sandboxDirUrl,
                                                                    includingPropertiesForKeys: [],
                                                                    options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        contents?.forEach({ url in
            try? FileManager.default.removeItem(at: url)
        })
    }
}

extension NSImage {
    fileprivate func appIcon(h: CGFloat = 35) -> NSImage {
        guard self.isValid else {
            return self
        }
        let size = NSSize(width: h, height: h)
        let newImage = NSImage(size: size)

        self.size = size
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .low
        NSGraphicsContext.saveGraphicsState()
        
        let cornerRadius: CGFloat = h / 5
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()
        self.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        newImage.unlockFocus()
        return newImage
    }
}
