//
//  Streetcars.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/2/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation

class Streetcars {
    var streetcars = [Streetcar]()
    
    func updateStreetcars(scObject: [AnyObject]) {
        for sc in scObject {
            var found = false;
            
            guard let streetcar_id = sc["streetcar_id"] as? Int,
                let x = sc["x"] as? Double,
                let y = sc["y"] as? Double,
                let route_id = sc["route_id"] as? Int,
                let heading = sc["heading"] as? Int,
                let speedkmhr = sc["speedkmhr"] as? Int,
                let predictable = sc["predictable"] as? Bool,
                let updated_at = sc["updated_at"] as? String,
                let idle = sc["idle"] as? String
            else {
                return
            }

            for streetcar in streetcars {
                if streetcar.streetcar_id == streetcar_id {
                    streetcar.x = x
                    streetcar.y = y
                    streetcar.heading = heading
                    streetcar.speedkmhr = speedkmhr
                    streetcar.predictable = predictable
                    streetcar.updated_at = updated_at
                    streetcar.idle = idle
                    
                    found = true
                }
            }

            if !found {
                let streetcar = Streetcar(
                    streetcar_id: streetcar_id,
                    x: x,
                    y: y,
                    route_id: route_id,
                    heading: heading,
                    speedkmhr: speedkmhr,
                    predictable: predictable,
                    updated_at: updated_at,
                    idle: idle)
                
                self.streetcars.append(streetcar)
                
                ViewController.createMarker(streetcar: streetcar)
            }
            
            found = false
        }
    }
    
    func findStreetcarById(id: Int) -> Any? {
        for streetcar in streetcars {
            if streetcar.streetcar_id == id {
                return streetcar
            }
        }
        
        return nil
    }
    
    func convertKmHrToMph(speed: Int) -> String {
        return String(format: "%.0f", round(Double(speed) * 0.62137119223733)) + " Mph"
    }
    
    func removeStreetcars() {
        for streetcar in streetcars {
            streetcar.marker?.map = nil
        }
        
        streetcars.removeAll(keepingCapacity: false)
    }

}
