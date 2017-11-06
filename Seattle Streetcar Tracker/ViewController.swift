//
//  ViewController.swift
//  Seattle Streetcar Tracker
//
//  Created by Jacob Ulrich on 11/2/17.
//  Copyright © 2017 Jacob Ulrich. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON

var map: GMSMapView!
var streetcars: Streetcars = Streetcars()
var scTimer: Timer?

var STREETCAR_IMAGE: UIImage?
var STREETCAR_ICON: UIImageView?

var STOP_IMAGE: UIImage?
var STOP_ICON: UIImageView?


class ViewController: UIViewController, GMSMapViewDelegate {
    
    override func loadView() {
        let camera = GMSCameraPosition.camera(withLatitude: 47.605403, longitude: -122.320826, zoom: 15.0)
        map = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        map.delegate = self
        
        view = map
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("Clicked")
        print(marker.position)
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        let infoWindow = Bundle.main.loadNibNamed("CustomInfoWindow", owner: self, options: nil)?.first! as! CustomInfoWindow
        
        if ((marker.userData as! MarkerData).type == "streetcar") {
            
            let id = (marker.userData as! MarkerData).id
            
            let streetcar = streetcars.findStreetcarById(id: id)
            
            if (streetcar != nil) {
                let sc = streetcar as! Streetcar
                
                infoWindow.idle.text = "\(sc.idle)"
                infoWindow.speed.text = "\(streetcars.convertKmHrToMph(speed: sc.speedkmhr))"
                infoWindow.location.text = "\(sc.x) \(sc.y)"
            }
        }
        
        
        return infoWindow
    }


    
    override func viewDidLoad() {
        super.viewDidLoad()

        STREETCAR_IMAGE = UIImage(named: "streetcar")!.withRenderingMode(.alwaysTemplate)
        STREETCAR_ICON = UIImageView(image: STREETCAR_IMAGE)
        STREETCAR_ICON?.tintColor = UIColor(named: "ltBlue")
        
        STOP_IMAGE = UIImage(named: "stop_icon")!.withRenderingMode(.alwaysTemplate)
        STOP_ICON = UIImageView(image: STOP_IMAGE)
        STOP_ICON?.tintColor = UIColor(named: "dkBlue")
        
        updateStreetcars()
        getStops()
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
            marker.map = map
            marker.iconView = STREETCAR_ICON
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.zIndex = 1
            
            let scData = MarkerData(type: "streetcar", id: streetcar.streetcar_id)
            
            marker.userData = scData
            
            streetcar.marker = marker
        }
    }
    
    func createStopMarker(stop: Stop) {
        DispatchQueue.main.async {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: stop.lat, longitude: stop.lon)
            marker.iconView = STOP_ICON
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.map = map
            
            let scData = MarkerData(type: "stop", id: stop.stopId)
            
            marker.userData = scData

            stop.marker = marker
        }
    }

    
    func updateMarkers() {
        DispatchQueue.main.async {
            for streetcar in streetcars.streetcars {
                streetcar.marker?.position = CLLocationCoordinate2D(latitude: streetcar.x, longitude: streetcar.y)
                streetcar.marker?.rotation = CLLocationDegrees(streetcar.heading)
            }
        }
    }
    
    func getStops() {
        let url = URL(string: "http://sc-dev.shadowline.net/api/routes/1")

        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            
            let json = JSON(data: data)
            
                for (_, stop) in json["route"]["stop"] {
                    let stopId: Int = stop["stopId"].intValue
                    let lat: Double = stop["lat"].doubleValue
                    let lon: Double = stop["lon"].doubleValue
                    let title: String = stop["title"].stringValue

                    let newStop = Stop(stopId: stopId, lat: lat, lon: lon, title: title)
                    self.createStopMarker(stop: newStop)
                }
                
                for (_, path) in json["route"]["path"] {
                    let polyPath = GMSMutablePath()
                    
                    for (_, point) in path["point"] {
                        polyPath.add(CLLocationCoordinate2D(latitude: point["lat"].doubleValue, longitude: point["lon"].doubleValue))
                    }
                    
                    self.drawPolyLine(path: polyPath)
                }
           
        }).resume()

    }
    
    func drawPolyLine(path: GMSMutablePath) {
        DispatchQueue.main.async {
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = UIColor(named: "polyline")!
            polyline.strokeWidth = 2
            polyline.map = map
        }
    }
    
    @objc func updateStreetcars() {
        let url = URL(string: "http://sc-dev.shadowline.net/api/streetcars/1")
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]

                streetcars.updateStreetcars(scObject: jsonArray)
                self.updateMarkers();
            } catch let error as NSError {
                print(error)
            }
        }).resume()

    }


}

