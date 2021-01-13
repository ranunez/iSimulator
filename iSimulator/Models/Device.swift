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
    
    var pairs: [Device] = []
    
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
        if self.state == .booted {
            try? self.shutdown()
        }
        var afterTime = 0.0
        if self.state == .booted {
            afterTime = 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + afterTime) {
            shell("/usr/bin/xcrun", arguments: "simctl", "erase", self.udid)
        }
    }
    
    func delete() throws {
        shell("/usr/bin/xcrun", arguments: "simctl", "delete", self.udid)
    }
    
    func updateAppGroups(with cache: AppGroupCache) {
        let appGroupContents = (try? FileManager.default.contentsOfDirectory(at: appGroupURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        var appGroups: [AppGroup] = []
        appGroupContents.enumerated().forEach { (offset, url) in
            let group = cache.groups.first { (appGroup) -> Bool in
                appGroup.fileURL == url
            }
            if let appGroup = group {
                appGroups.append(appGroup)
            } else {
                if let id = identifier(with: url) {
                    let appGroup = AppGroup.init(fileURL: url, id: id)
                    appGroups.append(appGroup)
                }
            }
        }
        appGroups = appGroups.filter { !$0.id.contains("com.apple") }
        self.appGroups = appGroups
        DispatchQueue.main.async {
            self.appGroups.forEach{ $0.createLinkDir(device: self) }
        }
    }
    
    func updateApps(with cache: ApplicationCache) {
        let bundleContents = (try? FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        
        let sandboxContents = (try? FileManager.default.contentsOfDirectory(at: sandboxURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        
        var apps: [Application] = []
        
        
        var newBundles = [URL]()
        bundleContents.enumerated().forEach { (offset, url) in
            if let app = cache.urlAndAppDic[url] {
                app.device = self
                apps.append(app)
            } else if cache.ignoreURLs.contains(url) {
                
            } else {
                newBundles.append(url)
            }
        }
        
        var newSandboxs = [URL]()
        sandboxContents.forEach { url in
            if !cache.sandboxURLs.contains(url) && !cache.ignoreURLs.contains(url) {
                newSandboxs.append(url)
            }
        }
        
        let idAndBundleUrlDic = identifierAndUrl(with: newBundles)
        var idAndSandboxUrlDic = identifierAndUrl(with: newSandboxs)
        
        idAndBundleUrlDic.forEach { (bundleID, bundleDirUrl) in
            guard let sandboxDirUrl = idAndSandboxUrlDic.removeValue(forKey: bundleID) else {
                return
            }
            if let app = Application(bundleID: bundleID, bundleDirUrl: bundleDirUrl, sandboxDirUrl: sandboxDirUrl){
                app.device = self
                apps.append(app)
            } else {
                cache.ignoreURLs.insert(bundleDirUrl)
            }
        }
        idAndSandboxUrlDic.forEach({ (_, url) in
            cache.ignoreURLs.insert(url)
        })
        self.applications = apps
        
        DispatchQueue.main.async {
          self.applications.forEach{ $0.createLinkDir() }
        }
    }
    
    private func identifierAndUrl(with urls: [URL]) -> [String: URL] {
        var dic: [String: URL] = [:]
        urls.forEach { (url) in
            if let identifier = self.identifier(with: url) {
                dic[identifier] = url
            }
        }
        return dic
    }
    
    private func identifier(with url: URL) -> String? {
        if let contents = NSDictionary(contentsOf: url.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")),
            let identifier = contents["MCMMetadataIdentifier"] as? String {
            return identifier
        }
        return nil
    }
}
