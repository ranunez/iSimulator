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

@discardableResult
func xcrun(arguments: String...) -> Result<Data, XCRunError> {
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

func xcrunFindXcodePath() -> Result<String, XCRunError> {
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
}

func xcrunFindSimulatorPath() -> Result<String, XCRunError> {
    switch xcrunFindXcodePath() {
    case .success(let xcodePath):
        return .success("\(xcodePath)/Applications/Simulator.app")
    case .failure(let error):
        return.failure(error)
    }
}

func xcrunOpenSimulatorApp() -> Result<Void, XCRunError> {
    switch xcrunFindSimulatorPath() {
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
