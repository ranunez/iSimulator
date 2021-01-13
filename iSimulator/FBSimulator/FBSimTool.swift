//
//  FBSimTool.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/8.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation
import FBSimulatorControl

final class FBSimTool {
    static let `default` = FBSimTool()
    
    private var allSimulators: [FBSimulator] {
        return self.control?.set.allSimulators ?? []
    }
    
    private let control: FBSimulatorControl? = {
        let options = FBSimulatorManagementOptions()
        let logger = FBControlCoreGlobalConfiguration.defaultLogger
        let config = FBSimulatorControlConfiguration(deviceSetPath: nil,
                                                     options: options,
                                                     logger: logger,
                                                     reporter: nil)
        return try? FBSimulatorControl.withConfiguration(config)
    }()
    
    func boot(_ udid: String) throws {
        if let sim = allSimulators.first(where: { $0.udid == udid }) {
            let future = sim.boot()
            try future.await(withTimeout: 20)
            sim.focus()
        } else {
            throw NSError(domain: "Boot Failed!", code: -1, userInfo: nil)
        }
    }
    
    func shutdown(_ udid: String) throws {
        if let sim = allSimulators.first(where: { $0.udid == udid }) {
            sim.shutdown()
        } else {
            throw NSError(domain: "Shutdown Failed!", code: -1, userInfo: nil)
        }
    }
    
}
