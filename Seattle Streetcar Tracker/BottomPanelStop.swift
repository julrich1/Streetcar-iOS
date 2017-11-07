//
//  BottomPanel.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/7/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation
import UIKit

class BottomPanelStop: UIView {
    @IBOutlet var title: UILabel!
    @IBOutlet var arrivals: UILabel!
    
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
    
    func showArrivals(titleStr: String, arrivalsStr: String) {
        DispatchQueue.main.async {
            self.title.text = titleStr
            self.arrivals.text = arrivalsStr
        }
    }
}
