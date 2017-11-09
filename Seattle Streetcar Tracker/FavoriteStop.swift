//
//  FavoriteStop.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/9/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation

class FavoriteStop {
    var id: Int
    var title: String
    var arrivalTime = ""
    
    init (id: Int, title: String) {
        self.id = id
        self.title = title
    }
}
