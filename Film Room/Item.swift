//
//  Item.swift
//  Film Room
//
//  Created by Sohil Sathe on 11/8/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
