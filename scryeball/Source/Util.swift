//
//  Util.swift
//  scryeball
//
//  Created by Johnny Sparks  on 10/8/18.
//  Copyright © 2018 Johnny Sparks . All rights reserved.
//

import Foundation

extension String: Error { }


extension Int {
    static func random(_ range: CountableRange<Int>) -> Int {
        let rand = Float(arc4random()) / Float(UInt32.max)
        return range.lowerBound + Int(Float(range.upperBound - range.lowerBound) * rand)
    }

    func times(_ execute: () -> ()) {
        guard self > 0 else { return }
        for _ in 0..<self {
            execute()
        }
    }
}
