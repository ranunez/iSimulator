//
//  NSImage+Extension.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/24.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

extension Array where Element:Equatable {
    func divideDuplicates() -> (result: [Element], duplicates: [Element]) {
        var result = [Element]()
        var duplicates = [Element]()
        for value in self {
            if result.contains(value) {
                duplicates.append(value)
            } else {
                result.append(value)
            }
        }
        
        return (result, duplicates)
    }
}
