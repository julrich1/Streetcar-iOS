//
//  Stop.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/3/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import GoogleMaps
import Foundation

class Stop {
    var stopId: Int
    var lat: Double
    var lon: Double
    var title: String
    var marker: GMSMarker?
    
    init(stopId: Int, lat: Double, lon: Double, title: String) {
        self.stopId = stopId
        self.lat = lat
        self.lon = lon
        self.title = title
    }
}
