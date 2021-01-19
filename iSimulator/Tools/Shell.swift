//
//  Shell.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

struct XCRunError: Error {
    let command: String
    let message: String
}

enum ShellCommand {
    private enum DeveloperPath {
        case xcodeApp
        case simulatorApp
        
        func execute() -> Result<String, XCRunError> {
            switch self {
            case .xcodeApp:
                switch xcrun(arguments: "xcode-select", "-p") {
                case .success(let xcodePathData):
                    guard let xcodePath = String(data: xcodePathData, encoding: .utf8) else {
                        return .failure(XCRunError(command: "", message: "xcode-select did not return a valid value."))
                    }
                    let normalizedXcodePath = xcodePath.replacingOccurrences(of: "\n", with: "")
                    return .success(normalizedXcodePath)
                case .failure(let error):
                    return .failure(error)
                }
            case .simulatorApp:
                switch ShellCommand.DeveloperPath.xcodeApp.execute() {
                case .success(let xcodePath):
                    return .success("\(xcodePath)/Applications/Simulator.app")
                case .failure(let error):
                    return.failure(error)
                }
            }
        }
    }
    
    enum Open {
        case simulatorApp
        
        func execute() -> Result<Void, XCRunError> {
            switch ShellCommand.DeveloperPath.simulatorApp.execute() {
            case .success(let simulatorPath):
                switch xcrun(arguments: "open", simulatorPath) {
                case .success:
                    return .success(())
                case .failure(let error):
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    enum List {
        case devices
        
        func execute() -> Result<[Runtime], XCRunError> {
            switch xcrun(arguments: "simctl", "list", "-j") {
            case .success(let jsonData):
                let decoder = JSONDecoder()
                do {
                    let runtimeList = try decoder.decode(RuntimeList.self, from: jsonData)
                    return .success(runtimeList.runtimes)
                } catch let error as DecodingError {
                    return .failure(XCRunError(command: "simctl list -j",
                                               message: error.localizedDescription))
                } catch {
                    return .failure(XCRunError(command: "simctl list -j",
                                               message: "Failed to decode 'RuntimeList' due to an unknown error"))
                }
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    enum Device: String {
        case boot
        case shutdown
        case erase
        case delete
        
        func execute(deviceUDID: UUID) -> Result<Void, XCRunError> {
            switch xcrun(arguments: "simctl", rawValue, deviceUDID.uuidString) {
            case .success:
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    enum App: String {
        case launch
        case terminate
        case uninstall
        
        func execute(deviceUDID: UUID, bundleId: String) {
            ShellCommand.xcrun(arguments: "simctl", rawValue, deviceUDID.uuidString, bundleId)
        }
    }
    
    @discardableResult private static func xcrun(arguments: String...) -> Result<Data, XCRunError> {
        let launchPath = "/usr/bin/xcrun"
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        process.launch()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if outputData.isEmpty {
            let command = "\(launchPath)\(arguments.reduce("", { "\($0) \($1)" }))"
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? ""
            let error = XCRunError(command: command, message: errorMessage)
            return .failure(error)
        } else {
            return .success(outputData)
        }
    }
}
