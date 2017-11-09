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
    @IBOutlet var loadSpinner: UIActivityIndicatorView!

    @IBOutlet var starButton: UIButton!
    
    let STAR_FULL_IMAGE = UIImage(named: "star_full")
    let STAR_EMPTY_IMAGE = UIImage(named: "star_empty")

    func hide() {
        DispatchQueue.main.async {
            self.isHidden = true
            self.title.isHidden = true
            self.arrivals.isHidden = true
            self.starButton.isHidden = true
        }
    }
    
    func show() {
        DispatchQueue.main.async {
            self.title.isHidden = true
            self.arrivals.isHidden = true
            self.starButton.isHidden = true
            self.loadSpinner.isHidden = false
            self.loadSpinner.startAnimating()
            self.isHidden = false
        }
    }
    
    func showArrivals(stop: Stop, arrivalsStr: String, favorited: Bool) {
        DispatchQueue.main.async {
            var icon: UIImage?
            
            self.loadSpinner.stopAnimating()
            self.loadSpinner.isHidden = true
            
            self.title.text = stop.title
            self.arrivals.text = arrivalsStr
            
            self.title.isHidden = false
            self.arrivals.isHidden = false
            
            if favorited {
                icon = self.STAR_FULL_IMAGE
            }
            else {
                icon = self.STAR_EMPTY_IMAGE
            }
            
            self.starButton.setImage(icon, for: UIControlState.normal)

            self.starButton.isHidden = false
        }
    }
}
