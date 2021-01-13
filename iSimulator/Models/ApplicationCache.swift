//
//  ApplicationCache.swift
//  iSimulator
//
//  Created by Peng Jin 靳朋 on 2018/12/1.
//  Copyright © 2018 niels.jin. All rights reserved.
//

import Foundation

final class ApplicationCache {

    var urlAndAppDic: [URL: Application] = [:]
    
    var sandboxURLs: Set<URL> = []
    
    var ignoreURLs: Set<URL> = []
    
    init() {
        
    }
}

final class AppGroupCache {
    var groups: Set<AppGroup> = []
}
