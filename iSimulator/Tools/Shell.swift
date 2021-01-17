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
        let command = "\(launchPath) \(arguments.reduce("", { "\($0) \($1)" }))"
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorMessage = String(data: errorData, encoding: .utf8) ?? ""
        let error = XCRunError(command: command, message: errorMessage)
        return .failure(error)
    } else {
        return .success(outputData)
    }
}
