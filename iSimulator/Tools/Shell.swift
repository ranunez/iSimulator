//
//  Shell.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

@discardableResult
func xcrun(arguments: String...) -> Data {
    let process = Process()
    process.launchPath = "/usr/bin/xcrun"
    process.arguments = arguments
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.launch()
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return outputData
}
