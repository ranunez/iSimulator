//
//  TotalModel.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import AppKit
import ObjectMapper

final class TotalModel: Mappable {
    static let `default` = TotalModel()
    var isForceUpdate = true
    
    private var lastXcodePath = ""
    private var appCache = ApplicationCache()
    private var groupCache = AppGroupCache()
    
    private func xcodePath() -> String {
        return shell("/usr/bin/xcrun", arguments: "xcode-select", "-p").outStr
    }
    
    func update() {
        let xcodePath = self.xcodePath()
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
        let jsonStr = shell("/usr/bin/xcrun", arguments: "simctl", "list", "-j").outStr
        _ = Mapper().map(JSONString: jsonStr, toObject: TotalModel.default)
    }
    
    var runtimes: [Runtime] = []
    
    func runtimes(osType: Runtime.OSType) -> [Runtime] {
        return runtimes.filter{$0.name.contains(osType.rawValue)}
    }
    
    private var devicetypes: [DeviceType] = []
    
    private var iOSDevicetypes: [DeviceType] {
        return devicetypes.filter{$0.name.contains("iPhone") || $0.name.contains("iPad")}
    }
    
    private var tvOSDevicetypes: [DeviceType] {
        return devicetypes.filter{$0.name.contains("TV")}
    }
    
    private var watchOSDevicetypes: [DeviceType] {
        return devicetypes.filter{$0.name.contains("Watch")}
    }
    
    private var devices: [String: [Device]] = [:]
    
    private var pairs: [String: Pair] = [:]
    
    private init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        runtimes.removeAll()
        devicetypes.removeAll()
        devices.removeAll()
        pairs.removeAll()
        runtimes <- map["runtimes"]
        devicetypes <- map["devicetypes"]
        devices <- map["devices"]
        pairs <- map["pairs"]
        // 关联 runtime 和 device/devicetype
        runtimes.forEach{ r in
            r.devices = self.devices[r.name] ?? (self.devices[r.identifier] ?? [])
            switch r.osType {
            case .iOS:
                r.devicetypes = self.iOSDevicetypes
            case .watchOS:
                r.devicetypes = self.watchOSDevicetypes
            case .tvOS:
                r.devicetypes = self.tvOSDevicetypes
            case .None:
                break
            }
            r.devices.forEach{
                $0.runtime = r
                $0.updateApps(with: appCache)
                $0.updateAppGroups(with: groupCache)
            }
        }
        
        let tempAllDevice: [Device] = runtimes.flatMap { $0.devices }
        pairs.forEach { (key, pair) in
            let watch = tempAllDevice.first(where: { (device) -> Bool in
                if let watch = pair.watch{
                    return device.udid == watch.udid
                } else {
                    return false
                }
            })
            let phone = tempAllDevice.first(where: { (device) -> Bool in
                if let phone = pair.phone{
                    return device.udid == phone.udid
                } else {
                    return false
                }
            })
            guard let w = watch, w.runtime != nil,
                let p = phone, p.runtime != nil else {
                return
            }
            w.pairUDID = key
            p.pairs.append(w)
        }
        
        self.updateCache()
    }
    
    private func updateCache() {
        let applications = runtimes.flatMap { $0.devices }.flatMap { $0.applications }
        
        var urlAndAppDicCache: [URL: Application] = [:]
        var sandboxURLsCache: Set<URL> = []
        
        applications.forEach { (app) in
            urlAndAppDicCache[app.bundleDirUrl] = app
            sandboxURLsCache.insert(app.sandboxDirUrl)
            //从旧的缓存中移除
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
