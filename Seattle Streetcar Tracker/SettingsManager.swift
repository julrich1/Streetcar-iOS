//
//  SettingsManager.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/9/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import Foundation

class SettingsManager {
    static func saveFavorites(favorites: FavoriteStops) {
        let defaults = UserDefaults.standard

        let sluDict = self.convertFavsToDictionary(favorites: favorites.slu)
        let fhsDict = self.convertFavsToDictionary(favorites: favorites.fhs)

        defaults.set(sluDict, forKey: "favorites-slu")
        defaults.set(fhsDict, forKey: "favorites-fhs")
    }
    
    static func loadFavorites() -> (slu: [FavoriteStop], fhs: [FavoriteStop]) {
        let defaults = UserDefaults.standard
        
        let codedSLU = defaults.array(forKey: "favorites-slu") ?? []
        let codedFHS = defaults.array(forKey: "favorites-fhs") ?? []
        
        let favoritesSLU = convertDictionaryToFavs(data: codedSLU as! [Data])
        let favoritesFHS = convertDictionaryToFavs(data: codedFHS as! [Data])

        return (slu: favoritesSLU, fhs: favoritesFHS)
    }
    
    static func convertFavsToDictionary(favorites: [FavoriteStop]) -> [Data] {
        var dictStops = [Data]()
        
        for stop in favorites {
            let dict = [stop.id: stop.title]
            
            dictStops.append(NSKeyedArchiver.archivedData(withRootObject: dict))
        }
        
        return dictStops
    }
    
    static func convertDictionaryToFavs(data: [Data]) -> [FavoriteStop] {
        var returnItem = [FavoriteStop]()
        for item in data {
            let decoded = NSKeyedUnarchiver.unarchiveObject(with: item) as! [Int: String]

            for (id, title) in decoded {
                returnItem.append(FavoriteStop(id: id, title: title))
            }
        }

        return returnItem
    }
    
    static func saveRoute(route: Int) {
        let defaults = UserDefaults.standard

        defaults.set(route, forKey: "route")
    }
    
    static func loadRoute() -> Int{
        let defaults = UserDefaults.standard
        let routeValue = defaults.integer(forKey: "route")
        
        return routeValue
    }
}
