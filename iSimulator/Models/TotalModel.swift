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
    var isForceUpdate = true
    
    private var lastXcodePath = ""
    private var appCache = ApplicationCache()
    private var groupCache = Set<AppGroup>()
    
    var runtimes: [Runtime] = []
    
    func update() {
        let xcodePath = shell("/usr/bin/xcrun", arguments: "xcode-select", "-p").outputString
        if lastXcodePath != xcodePath {
            isForceUpdate = true
            lastXcodePath = xcodePath
        }
        if isForceUpdate {
            isForceUpdate = false
            appCache = ApplicationCache()
            groupCache = Set<AppGroup>()
            DispatchQueue.main.async {
                RootLink.createDir()
            }
        }
        let jsonData = shell("/usr/bin/xcrun", arguments: "simctl", "list", "-j").outputData
        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
            fatalError()
        }
        
        let devices: [String: [Device]]
        if let rawDevices = json["devices"] as? [String: [[String: Any]]] {
            var devicesTemp = [String: [Device]]()
            for (key, values) in rawDevices {
                devicesTemp[key] = values.map({ iSimulator.Device(json: $0) })
            }
            
            devices = devicesTemp
        } else {
            fatalError()
        }
        
        var urlAndAppDicCache: [URL: Application] = [:]
        var sandboxURLsCache: Set<URL> = []
        if let rawRunTimes = json["runtimes"] as? [[String: Any]] {
            runtimes = rawRunTimes.map({ iSimulator.Runtime(json: $0) })
            
            runtimes.forEach { runtime in
                runtime.devices = devices[runtime.name] ?? devices[runtime.identifier] ?? []
                
                runtime.devices.forEach {
                    $0.runtime = runtime
                    $0.updateApps(with: appCache)
                    $0.updateAppGroups(groupCache: groupCache)
                }
            }
            
            runtimes.flatMap { $0.devices }.flatMap { $0.applications }.forEach { app in
                urlAndAppDicCache[app.bundleDirUrl] = app
                sandboxURLsCache.insert(app.sandboxDirUrl)
                
                self.appCache.urlAndAppDic.removeValue(forKey: app.bundleDirUrl)
                self.appCache.sandboxURLs.remove(app.sandboxDirUrl)
            }
        } else {
            runtimes = []
        }
        
        let invalidApp = self.appCache.urlAndAppDic
        DispatchQueue.main.async {
            invalidApp.forEach { $0.value.removeLinkDir() }
        }
        
        self.appCache.urlAndAppDic = urlAndAppDicCache
        self.appCache.sandboxURLs = sandboxURLsCache
    }
}
