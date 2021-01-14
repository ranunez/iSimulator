//
//  TotalModel.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//
import Foundation
import AppKit

final class TotalModel {
    static let `default` = TotalModel()
    
    private var lastXcodePath = ""
    private var appCache = ApplicationCache()
    
    var runtimes: [Runtime] = []
    
    func update(isForceUpdate: Bool) {
        let xcodePathData = xcrun(arguments: "xcode-select", "-p")
        if let xcodePath = String(data: xcodePathData, encoding: .utf8), lastXcodePath != xcodePath {
            lastXcodePath = xcodePath
            updateCache()
        }
        if isForceUpdate {
            updateCache()
        }
        let jsonData = xcrun(arguments: "simctl", "list", "-j")
        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
            fatalError()
        }
        
        if let rawRunTimes = json["runtimes"] as? [[String: Any]], let rawDevices = json["devices"] as? [String: [[String: Any]]] {
            runtimes = rawRunTimes.map({ iSimulator.Runtime(json: $0) })
            
            let devices = rawDevices.reduce([String: [Device]]()) { (result, rawDevice) -> [String: [Device]] in
                var updatedResult = result
                updatedResult[rawDevice.key] = rawDevice.value.map({ iSimulator.Device(json: $0) })
                return updatedResult
            }
            
            var urlAndAppDicCache = [URL: Application]()
            var sandboxURLsCache = Set<URL>()
            runtimes.forEach { runtime in
                runtime.devices = devices[runtime.name] ?? devices[runtime.identifier] ?? []
                
                runtime.devices.forEach {
                    $0.runtime = runtime
                    $0.updateApps(with: appCache)
                    $0.updateAppGroups()
                    
                    $0.applications.forEach { app in
                        app.removeLinkDir()
                        urlAndAppDicCache[app.bundleDirUrl] = app
                        sandboxURLsCache.insert(app.sandboxDirUrl)
                    }
                }
            }
            
            self.appCache.urlAndAppDic = urlAndAppDicCache
            self.appCache.sandboxURLs = sandboxURLsCache
        } else {
            runtimes = []
            appCache.urlAndAppDic = [:]
            appCache.sandboxURLs = []
        }
    }
    
    private func updateCache() {
        appCache = ApplicationCache()
        DispatchQueue.main.async {
            let rootLinkURL = UserDefaults.standard.rootLinkURL
            let contents = try? FileManager.default.contentsOfDirectory(at: rootLinkURL,
                                                                        includingPropertiesForKeys: [.isHiddenKey],
                                                                        options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants])
            contents?.filter({ $0.pathComponents.last == "Icon\r" }).forEach({ _ in try? FileManager.default.removeItem(at: rootLinkURL) })
            try? FileManager.default.createDirectory(at: rootLinkURL, withIntermediateDirectories: true)
            NSWorkspace.shared.setIcon(#imageLiteral(resourceName: "statusItem_icon"), forFile: rootLinkURL.path, options:[])
        }
    }
}
