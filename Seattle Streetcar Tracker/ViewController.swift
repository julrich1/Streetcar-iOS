//
//  ViewController.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/2/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import UIKit
import GoogleMaps

var mapView: GMSMapView?
var streetcars: Streetcars = Streetcars()
var scTimer: Timer?

class ViewController: UIViewController {
    
    override func loadView() {
        let camera = GMSCameraPosition.camera(withLatitude: 47.605403, longitude: -122.320884, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
    
//        createMarker(lat:47.605403, lon:-122.320884)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        updateStreetcars()
        scTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateStreetcars), userInfo: nil, repeats: true)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func createMarker(streetcar: Streetcar) {
        DispatchQueue.main.async {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: streetcar.x, longitude: streetcar.y)
//            marker.title = "Sydney"
//            marker.snippet = "Australia"
            marker.map = mapView
            streetcar.marker = marker
        }
    }
    
    func updateMarkers() {
        for streetcar in streetcars.streetcars {
            streetcar.marker?.position = CLLocationCoordinate2D(latitude: streetcar.x, longitude: streetcar.y)
        }
    }
    
    @objc func updateStreetcars() {
        let url = URL(string: "http://sc-dev.shadowline.net/api/streetcars/1")
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]

//                print(jsonArray)
//                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
//                let posts = json[""] as? [[String: Any]] ?? []
//                print(posts)
                streetcars.updateStreetcars(scObject: jsonArray)
                self.updateMarkers();
//
//                for streetcar in streetcars.streetcars {
//                    ViewController.createMarker(streetcar: streetcar)
//                }
//                if let array = jsonArray as? [AnyObject] {
//                    if let firstObject = array.first {
//                        // access individual object in array
//                        print(firstObject["idle"])
//                    }
//
//                    for object in array {
//                        // access all objects in array
//                    }
//                }
            } catch let error as NSError {
                print(error)
            }
        }).resume()

    }


}

