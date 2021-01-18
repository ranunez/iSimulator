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
    
    private(set) var linkURL: URL?
    
    lazy private(set) var attributeStr: NSMutableAttributedString = {
        let name = "\(bundleDisplayName) - \(bundleShortVersion)(\(bundleVersion))"
        let other = "\n\(bundleID)"
        let att = NSMutableAttributedString(string: name + other)
        att.addAttributes([NSAttributedString.Key.font: NSFont.systemFont(ofSize: 13)], range: NSRange(location: 0, length: name.count))
        att.addAttributes([NSAttributedString.Key.font: NSFont.systemFont(ofSize: 11), NSAttributedString.Key.foregroundColor: NSColor.lightGray], range: NSRange(location: name.count, length: other.count))
        return att
    }()
    
    init?(bundleID: String, bundleDirUrl: URL, sandboxDirUrl: URL, device: Device) {
        self.bundleID = bundleID
        self.bundleDirUrl = bundleDirUrl
        self.sandboxDirUrl = sandboxDirUrl
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: bundleDirUrl,
                                                                          includingPropertiesForKeys: nil,
                                                                          options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else {
            return nil
        }
        
        guard let appURL = contents.first(where: { $0.pathExtension == "app" }) else { return nil }
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
        
        
        let iconFile: String?
        if let cfBundleIconsDictionary = appInfoDict["CFBundleIcons"] as? [String: Any], let cfBundlePrimaryIconDictionary = cfBundleIconsDictionary["CFBundlePrimaryIcon"] as? [String: Any], let icons = cfBundlePrimaryIconDictionary["CFBundleIconFiles"] as? [String] {
            iconFile = icons.last
        } else if let cfBundleIconsDictionary = appInfoDict["CFBundleIcons~ipad"] as? [String: Any], let cfBundlePrimaryIconDictionary = cfBundleIconsDictionary["CFBundlePrimaryIcon"] as? [String: Any], let icons = cfBundlePrimaryIconDictionary["CFBundleIconFiles"] as? [String] {
            iconFile = icons.last?.appending("@2x~ipad")
        } else {
            iconFile = "Icon.png"
        }
        
        if let iconFile = iconFile, let bundle = Bundle(url: appUrl), let im = bundle.image(forResource: iconFile) {
            originImage = im
            image = im.appIcon()
        } else {
            originImage = #imageLiteral(resourceName: "default_ios_app_icon")
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
        xcrun(arguments: "simctl", "launch", device.udid, bundleID)
    }
    
    func terminate(device: Device) {
        xcrun(arguments: "simctl", "terminate", device.udid, bundleID)
    }
    
    func uninstall(device: Device) {
        self.terminate(device: device)
        xcrun(arguments: "simctl", "uninstall", device.udid, bundleID)
    }
    
    func resetContent() {
        let contents = try? FileManager.default.contentsOfDirectory(at: sandboxDirUrl,
                                                                    includingPropertiesForKeys: [],
                                                                    options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        contents?.forEach({ url in
            try? FileManager.default.removeItem(at: url)
        })
    }
    
    func createLinkDir(device: Device, runtime: Runtime) {
        guard linkURL == nil else { return }
        var url = UserDefaults.standard.rootLinkURL
        url.appendPathComponent(runtime.name)
        
        if runtime.devices.filter({ $0.name == device.name }).count > 1 {
            url.appendPathComponent("\(device.name)_\(device.udid)")
        } else {
            url.appendPathComponent(device.name)
        }
        
        if device.applications.filter({ $0.bundleDisplayName == bundleDisplayName }).count > 1 {
            url.appendPathComponent("\(bundleDisplayName)_\(bundleID)")
        } else {
            url.appendPathComponent(bundleDisplayName)
        }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            self.linkURL = url
        } catch {
            return
        }
        let bundleURL = url.appendingPathComponent("Bundle")
        let sandboxURL = url.appendingPathComponent("Sandbox")
        createSymbolicLink(at: bundleURL, withDestinationURL: bundleDirUrl)
        createSymbolicLink(at: sandboxURL, withDestinationURL: sandboxDirUrl)
        
        NSWorkspace.shared.setIcon(originImage, forFile: url.path, options:[])
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
        guard let url = linkURL else { return }
        let bundleURL = url.appendingPathComponent("Bundle")
        if let destinationUrlPath = try? FileManager.default.destinationOfSymbolicLink(atPath: bundleURL.path),
            FileManager.default.fileExists(atPath: destinationUrlPath){
            return
        }
        try? FileManager.default.removeItem(at: url)
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

extension UserDefaults {
    static let kUserDefaultDocumentKey = "kUserDefaultDocumentKey"
    static let kDocumentName = "iSimulator"
    
    var rootLinkURL: URL {
        let url: URL
        if let path = string(forKey: Self.kUserDefaultDocumentKey) {
            url = URL(fileURLWithPath: path)
        } else {
            url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        return url.appendingPathComponent(Self.kDocumentName)
    }
}
