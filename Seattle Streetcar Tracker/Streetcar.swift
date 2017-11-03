//
//  Streetcar.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/2/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation
import GoogleMaps

class Streetcar {
    var streetcar_id: Int
    var x: Double
    var y: Double
    var route_id: Int
    var heading: Int
    var speedkmhr: Int
    var predictable: Bool
    var updated_at: String
    var idle: String
    var marker: GMSMarker?

    
    init(streetcar_id: Int, x: Double, y: Double, route_id: Int, heading: Int, speedkmhr: Int, predictable: Bool, updated_at: String, idle: String) {
        
        self.streetcar_id = streetcar_id
        self.x = x
        self.y = y
        self.route_id = route_id
        self.heading = heading
        self.speedkmhr = speedkmhr
        self.predictable = predictable
        self.updated_at = updated_at
        self.idle = idle
    }
}
