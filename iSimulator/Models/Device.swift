//
//  Device.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

final class Device {
    enum State: String {
        case booted = "Booted"
        case shutdown = "Shutdown"
    }
    
    let state: State
    
    let name: String
    
    let udid: String
    
    var applications: [Application] = []
    
    var appGroups: [AppGroup] = []
    
    weak var runtime: Runtime!
    
    var dataURL: URL {
        return Device.url.appendingPathComponent("\(self.udid)/data")
    }
    
    var sandboxURL: URL {
        return Device.url.appendingPathComponent("\(self.udid)/data/Containers/Data/Application")
    }
    
    var bundleURL: URL {
        return Device.url.appendingPathComponent("\(self.udid)/data/Containers/Bundle/Application")
    }
    
    var appGroupURL: URL {
        return Device.url.appendingPathComponent("\(self.udid)/data/Containers/Shared/AppGroup")
    }
    
    var infoURL: URL {
        return Device.url.appendingPathComponent("\(self.udid)/device.plist")
    }
    
    init(json: [String: Any]) {
        guard let rawState = json["state"] as? String else {
            fatalError()
        }
        guard let state = State(rawValue: rawState) else {
            fatalError()
        }
        guard let name = json["name"] as? String else {
            fatalError()
        }
        guard let udid = json["udid"] as? String else {
            fatalError()
        }
        
        self.state = state
        self.name = name
        self.udid = udid
    }
    
    static let url: URL = {
        let userLibraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return userLibraryURL.appendingPathComponent("Developer/CoreSimulator/Devices")
    }()
    
    func boot() throws {
        try? FBSimTool.default.boot(self.udid)
    }
    
    func shutdown() throws {
        try? FBSimTool.default.shutdown(self.udid)
    }
    
    func erase() throws {
        if state == .booted {
            try? shutdown()
        }
        let afterTime: TimeInterval
        switch state {
        case .booted:
            afterTime = 0.3
        case .shutdown:
            afterTime = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + afterTime) {
            shell("/usr/bin/xcrun", arguments: "simctl", "erase", self.udid)
        }
    }
    
    func delete() throws {
        shell("/usr/bin/xcrun", arguments: "simctl", "delete", self.udid)
    }
    
    func updateAppGroups(groupCache: Set<AppGroup>) {
        let appGroupContents = (try? FileManager.default.contentsOfDirectory(at: appGroupURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        
        self.appGroups = appGroupContents.compactMap { url -> AppGroup? in
            if let appGroup = groupCache.first(where: { $0.fileURL == url && !$0.id.contains("com.apple") }) {
                return appGroup
            } else if let id = identifier(with: url), !id.contains("com.apple") {
                return AppGroup(fileURL: url, id: id)
            } else {
                return nil
            }
        }
        
        DispatchQueue.main.async {
            self.appGroups.forEach{ $0.createLinkDir(device: self) }
        }
    }
    
    func updateApps(with cache: ApplicationCache) {
        let bundleContents = (try? FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        
        let sandboxContents = (try? FileManager.default.contentsOfDirectory(at: sandboxURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        
        let newBundles = bundleContents.filter({ !cache.ignoreURLs.contains($0) })
        
        var apps = bundleContents.compactMap { url -> Application? in
            guard let app = cache.urlAndAppDic[url] else { return nil }
            app.device = self
            return app
        }
        
        let newSandboxs = sandboxContents.filter({ !cache.sandboxURLs.contains($0) && !cache.ignoreURLs.contains($0) })
        
        let idAndBundleUrlDic = identifierAndUrl(with: newBundles)
        var idAndSandboxUrlDic = identifierAndUrl(with: newSandboxs)
        
        idAndBundleUrlDic.forEach { (bundleID, bundleDirUrl) in
            guard let sandboxDirUrl = idAndSandboxUrlDic.removeValue(forKey: bundleID) else {
                return
            }
            if let app = Application(bundleID: bundleID, bundleDirUrl: bundleDirUrl, sandboxDirUrl: sandboxDirUrl) {
                app.device = self
                apps.append(app)
            } else {
                cache.ignoreURLs.insert(bundleDirUrl)
            }
        }
        idAndSandboxUrlDic.forEach({ cache.ignoreURLs.insert($0.value) })
        self.applications = apps
        
        DispatchQueue.main.async {
          self.applications.forEach{ $0.createLinkDir() }
        }
    }
    
    private func identifierAndUrl(with urls: [URL]) -> [String: URL] {
        return urls.reduce([String: URL]()) { (result, url) -> [String: URL] in
            guard let identifier = self.identifier(with: url) else { return result }
            var updatedResult = result
            updatedResult[identifier] = url
            return updatedResult
        }
    }
    
    private func identifier(with url: URL) -> String? {
        let plistURL = url.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
        guard let contents = NSDictionary(contentsOf: plistURL) else { return nil }
        guard let identifier = contents["MCMMetadataIdentifier"] as? String else { return nil }
        return identifier
    }
}
