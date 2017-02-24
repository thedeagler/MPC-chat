//
//  Constants.swift
//  MPCRevisited
//
//  Created by Stephen Wu on 2/23/17.
//  Copyright © 2017 Appcoda. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let serviceType = "marcopolo-chat"
    
    static var displayName: String {
        get {
            return UIDevice.current.name
        }
    }
}
