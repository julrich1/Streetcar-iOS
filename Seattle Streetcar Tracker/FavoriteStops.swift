//
//  FavoriteStops.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/9/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation

class FavoriteStops {
    var fhs: [FavoriteStop] = []
    var slu: [FavoriteStop] = []
    
    func add(id: Int, title: String, route: Int) {
        if route == 1 {
            fhs.append(FavoriteStop(id: id, title: title))
        }
        else if route == 2 {
            slu.append(FavoriteStop(id: id, title: title))
        }
    }
    
    func remove(id: Int, route: Int) {
        if route == 1 {
            for (index, stop) in fhs.enumerated() {
                if stop.id == id {
                    fhs.remove(at: index)
                    break
                }
            }
        }
        else if route == 2 {
            for (index, stop) in slu.enumerated() {
                if stop.id == id {
                    slu.remove(at: index)
                    break
                }
            }
        }
    }
    
    func isFavorited(id: Int, route: Int) -> Bool {
        if route == 1 {
            for stop in fhs {
                if id == stop.id {
                    return true
                }
            }
        }
        else if route == 2 {
            for stop in slu {
                if id == stop.id {
                    return true
                }
            }
        }
        
        return false
    }
    
    func findById(id: Int, route: Int) -> FavoriteStop {
        if route == 1 {
            for stop in fhs {
                if id == stop.id {
                    return stop
                }
            }
        }
        else if route == 2 {
            for stop in slu {
                if id == stop.id {
                    return stop
                }
            }
        }
        
        return FavoriteStop(id: 0, title: "")
    }
    
    func getQueryString(route: Int) -> String {
        var url = API_URL + "api/routes/" + String(route) + "/arrivals/"
        
        if route == 1 {
            for stop in fhs {
                url += String(stop.id) + ","
            }
        }
        else {
            for stop in slu {
                url += String(stop.id) + ","
            }
        }
        
        return url
    }
}
