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
    private var groupCache = AppGroupCache()
    
    var runtimes: [Runtime] = []
    
    func update() {
        let xcodePath = shell("/usr/bin/xcrun", arguments: "xcode-select", "-p").outputString
        if lastXcodePath != xcodePath{
            isForceUpdate = true
            lastXcodePath = xcodePath
        }
        if isForceUpdate {
            isForceUpdate = false
            appCache = ApplicationCache()
            groupCache = AppGroupCache()
            DispatchQueue.main.async {
                RootLink.createDir()
            }
        }
        let jsonData = shell("/usr/bin/xcrun", arguments: "simctl", "list", "-j").outputData
        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
            fatalError()
        }
        
        if let rawRunTimes = json["runtimes"] as? [[String: Any]] {
            runtimes = rawRunTimes.map({ iSimulator.Runtime(json: $0) })
        } else {
            runtimes = []
        }
        
        let devicetypes: [DeviceType]
        if let rawDeviceTypes = json["devicetypes"] as? [[String: Any]] {
            devicetypes = rawDeviceTypes.map({ DeviceType(json: $0) })
        } else {
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
        
        let pairs: [String: Pair]
        if let rawPairs = json["pairs"] as? [String: [String: Any]] {
            var pairsTemp = [String: Pair]()
            for (key, innerJSON) in rawPairs {
                pairsTemp[key] = Pair(json: innerJSON)
            }
            pairs = pairsTemp
        } else {
            fatalError()
        }
        
        runtimes.forEach { r in
            r.devices = devices[r.name] ?? (devices[r.identifier] ?? [])
            switch r.osType {
            case .iOS:
                r.devicetypes = devicetypes.filter{ $0.name.contains("iPhone") || $0.name.contains("iPad") }
            case .watchOS:
                r.devicetypes = devicetypes.filter{ $0.name.contains("Watch") }
            case .tvOS:
                r.devicetypes = devicetypes.filter{ $0.name.contains("TV") }
            case .None:
                break
            }
            r.devices.forEach {
                $0.runtime = r
                $0.updateApps(with: appCache)
                $0.updateAppGroups(with: groupCache)
            }
        }
        
        let tempAllDevice: [Device] = runtimes.flatMap { $0.devices }
        pairs.forEach { (key, pair) in
            let watch = tempAllDevice.first(where: { device -> Bool in
                if let watch = pair.watch {
                    return device.udid == watch.udid
                } else {
                    return false
                }
            })
            let phone = tempAllDevice.first(where: { device -> Bool in
                if let phone = pair.phone {
                    return device.udid == phone.udid
                } else {
                    return false
                }
            })
            guard let w = watch, w.runtime != nil,
                let p = phone, p.runtime != nil else {
                return
            }
            p.pairs.append(w)
        }
        
        let applications = runtimes.flatMap { $0.devices }.flatMap { $0.applications }
        
        var urlAndAppDicCache: [URL: Application] = [:]
        var sandboxURLsCache: Set<URL> = []
        
        applications.forEach { (app) in
            urlAndAppDicCache[app.bundleDirUrl] = app
            sandboxURLsCache.insert(app.sandboxDirUrl)
            
            self.appCache.urlAndAppDic.removeValue(forKey: app.bundleDirUrl)
            self.appCache.sandboxURLs.remove(app.sandboxDirUrl)
        }
        
        let invalidApp = self.appCache.urlAndAppDic
        DispatchQueue.main.async {
            invalidApp.forEach { $0.value.removeLinkDir() }
        }
        
        self.appCache.urlAndAppDic = urlAndAppDicCache
        self.appCache.sandboxURLs = sandboxURLsCache
    }
}
