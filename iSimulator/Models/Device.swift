//
//  Device.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

struct Device: Decodable {
    enum State: String, Decodable {
        case booted = "Booted"
        case shutdown = "Shutdown"
    }
    
    let state: State
    
    let name: String
    
    let udid: UUID
    
    let applications: [Application]
    
    let dataURL: URL
    
    let sandboxURL: URL
    
    let bundleURL: URL
    
    let infoURL: URL
    
    static let url: URL = {
        let userLibraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return userLibraryURL.appendingPathComponent("Developer/CoreSimulator/Devices")
    }()
    
    private enum CodingKeys: CodingKey {
        case state
        case name
        case udid
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(State.self, forKey: .state)
        name = try container.decode(String.self, forKey: .name)
        udid = try container.decode(UUID.self, forKey: .udid)
        
        bundleURL = Device.url.appendingPathComponent("\(udid)/data/Containers/Bundle/Application")
        sandboxURL = Device.url.appendingPathComponent("\(udid)/data/Containers/Data/Application")
        infoURL = Device.url.appendingPathComponent("\(udid)/device.plist")
        dataURL = Device.url.appendingPathComponent("\(udid)/data")
        
        let idAndBundleUrlDic = Self.identifierAndUrl(with: bundleURL.files)
        let idAndSandboxUrlDic = Self.identifierAndUrl(with: sandboxURL.files)
        
        self.applications = idAndBundleUrlDic.compactMap { (bundleID, bundleDirUrl) -> Application? in
            guard let sandboxDirUrl = idAndSandboxUrlDic[bundleID] else {
                return nil
            }
            guard let app = Application(bundleID: bundleID,
                                        bundleDirUrl: bundleDirUrl,
                                        sandboxDirUrl: sandboxDirUrl) else {
                return nil
            }
            return app
        }
    }
    
    func boot() -> Result<Void, XCRunError> {
        _ = ShellCommand.Open.simulatorApp.execute()
        return ShellCommand.Device.boot.execute(deviceUDID: udid)
    }
    
    func shutdown() -> Result<Void, XCRunError> {
        _ = ShellCommand.Open.simulatorApp.execute()
        return ShellCommand.Device.shutdown.execute(deviceUDID: udid)
    }
    
    func erase() -> Result<Void, XCRunError> {
        _ = ShellCommand.Open.simulatorApp.execute()
        if state == .booted {
            switch shutdown() {
            case .success:
                break
            case .failure(let error):
                return .failure(error)
            }
        }
        return ShellCommand.Device.erase.execute(deviceUDID: udid)
    }
    
    func delete() -> Result<Void, XCRunError> {
        _ = ShellCommand.Open.simulatorApp.execute()
        return ShellCommand.Device.delete.execute(deviceUDID: udid)
    }
    
    private static func identifierAndUrl(with urls: [URL]) -> [String: URL] {
        return urls.reduce([String: URL]()) { (result, url) -> [String: URL] in
            let plistURL = url.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let contents = NSDictionary(contentsOf: plistURL) else { return result }
            guard let bundleId = contents["MCMMetadataIdentifier"] as? String else { return result }
            var updatedResult = result
            updatedResult[bundleId] = url
            return updatedResult
        }
    }
}

extension URL {
    var files: [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: self,
                                                               includingPropertiesForKeys: [.isDirectoryKey],
                                                               options: [.skipsHiddenFiles,
                                                                         .skipsPackageDescendants,
                                                                         .skipsSubdirectoryDescendants])
        } catch {
            return []
        }
    }
}
