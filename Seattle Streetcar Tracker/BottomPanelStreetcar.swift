//
//  BottomPanelStreetcar.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/7/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation

import Foundation
import UIKit

class BottomPanelStreetcar: UIView {
    @IBOutlet var idle: UILabel!
    @IBOutlet var speed: UILabel!
    @IBOutlet var location: UILabel!
    
    func hide() {
        DispatchQueue.main.async {
            self.isHidden = true
        }
    }
    
    func show() {
        DispatchQueue.main.async {
            self.isHidden = false
        }
    }
    
    func showStreetcar(idle: String, speed: String, location: String) {
        DispatchQueue.main.async {
            self.idle.text = "Idle time: " + idle
            self.speed.text = "Last speed: " + speed
            self.location.text = "Location: " + location
        }
    }
}
