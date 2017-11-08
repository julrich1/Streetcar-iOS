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

var streetcars: Streetcars = Streetcars()
var stops = [Stop]()

var map: GMSMapView!
var scTimer: Timer?

var STREETCAR_IMAGE: UIImage?
var STREETCAR_ICON: UIImageView?

var STOP_IMAGE: UIImage?
var STOP_ICON: UIImageView?


class ViewController: UIViewController, GMSMapViewDelegate {
    @IBOutlet weak var mapContainerView: GMSMapView!
    @IBOutlet var bottomStopPanel: BottomPanelStop!
    @IBOutlet var bottomStreetcarPanel: BottomPanelStreetcar!
    
//    override func loadView() {
//        let camera = GMSCameraPosition.camera(withLatitude: 47.605403, longitude: -122.320826, zoom: 15.0)
//        map = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
//        map.delegate = self
//
//        view = map
////        self.view.addSubview(map)
////        self.view.insertSubview(map, at: 0)
//    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("Clicked")
        print(marker.position)
        
        if ((marker.userData as! MarkerData).type == "streetcar") {
            bottomStopPanel.hide()
            bottomStreetcarPanel.show()
            
            let id = (marker.userData as! MarkerData).id
            let streetcar = streetcars.findStreetcarById(id: id)
            
            if (streetcar != nil) {
                let sc = streetcar as! Streetcar
                
                self.bottomStreetcarPanel.showStreetcar(idle: sc.idle, speed: streetcars.convertKmHrToMph(speed: sc.speedkmhr), location: "\(sc.x) \(sc.y)")
            }
        }
        else if ((marker.userData as! MarkerData).type == "stop") {
            bottomStreetcarPanel.hide()
            bottomStopPanel.show()
            
            let id = (marker.userData as! MarkerData).id
            
            for stop in stops {
                if stop.stopId == id {
                    print("Match found!")
                    
                    getStopArrivals(stop: stop, complete: {(arrivalStr: String) -> Void in
                        print ("ArrivalSTR is: ", arrivalStr)
                        self.bottomStopPanel.showArrivals(titleStr: stop.title, arrivalsStr: arrivalStr)
                    })
                }
            }
        }

        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("Map clicked")
        bottomStopPanel.hide()
        bottomStreetcarPanel.hide()
    }
    
//    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
//        var infoWindow: AnyObject?
//
////        marker.tracksInfoWindowChanges = true
//        
//        if ((marker.userData as! MarkerData).type == "streetcar") {
//            bottomPanel.isHidden = false
//
//            infoWindow = Bundle.main.loadNibNamed("CustomInfoWindow", owner: self, options: nil)?.first! as! CustomInfoWindow
//
//            let id = (marker.userData as! MarkerData).id
//            let streetcar = streetcars.findStreetcarById(id: id)
//
//            if (streetcar != nil) {
//                let sc = streetcar as! Streetcar
//
//                let iw = infoWindow as! CustomInfoWindow
//                iw.idle.text = "\(sc.idle)"
//                iw.speed.text = "\(streetcars.convertKmHrToMph(speed: sc.speedkmhr))"
//                iw.location.text = "\(sc.x) \(sc.y)"
//            }
//        }
//        else if ((marker.userData as! MarkerData).type == "stop") {
//            bottomPanel.isHidden = false
//            infoWindow = Bundle.main.loadNibNamed("CustomInfoWindowStop", owner: self, options: nil)?.first! as! CustomInfoWindowStop
//
//            let id = (marker.userData as! MarkerData).id
//
//            for stop in stops {
//                if stop.stopId == id {
//                    print("Match found!")
//                    let iw = infoWindow as! CustomInfoWindowStop
//
//                    iw.title.text = stop.title
//                    getStopArrivals(stop: stop, complete: {(arrivalStr: String) -> Void in
//                        print ("ArrivalSTR is: ", arrivalStr)
//                            DispatchQueue.main.async {
//                                infoWindow = Bundle.main.loadNibNamed("CustomInfoWindowStop", owner: self, options: nil)?.first! as! CustomInfoWindowStop
//                                
//                                let iw = infoWindow as! CustomInfoWindowStop
//
//                                iw.title.text = stop.title
//                                iw.arrivals.text = arrivalStr
//
//                            }
//                        })
//
//                    return iw
//                }
//            }
//        }
//
//        return infoWindow as? UIView
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        map = mapContainerView
        
        let camera = GMSCameraPosition.camera(withLatitude: 47.605403, longitude: -122.320826, zoom: 15.0)
//        map = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        map.moveCamera(GMSCameraUpdate.setCamera(camera))
        map.delegate = self
        //
        //        view = map
        ////        self.view.addSubview(map)
        ////        self.view.insertSubview(map, at: 0)

        self.view.addSubview(map!)
        self.view.sendSubview(toBack: map)

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
            
                var json: JSON
            
                do {
                    json = try JSON(data: data)
                }
                catch {
                    print("There was an error fetching routes")
                    return
                }
            
                for (_, stop) in json["route"]["stop"] {
                    let stopId: Int = stop["stopId"].intValue
                    let lat: Double = stop["lat"].doubleValue
                    let lon: Double = stop["lon"].doubleValue
                    let title: String = stop["title"].stringValue

                    let newStop = Stop(stopId: stopId, lat: lat, lon: lon, title: title)
                    stops.append(newStop)
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
    
    func getStopArrivals(stop: Stop, complete: @escaping (String) -> Void) {
        let url = URL(string: "http://webservices.nextbus.com/service/publicJSONFeed?command=predictions&a=seattle-sc&r=FHS&s=\(stop.stopId)")
        
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }

            var json: JSON
            
            do {
                json = try JSON(data: data)
            }
            catch {
                print("There was an error fetching arrival times")
                return
            }
            
            var predStr = "Arriving in "
            
            for (_, prediction) in json["predictions"]["direction"]["prediction"] {
                predStr += prediction["minutes"].stringValue + ", "
            }
            
            let range = predStr.index(predStr.endIndex, offsetBy: -2)..<predStr.endIndex
            predStr.removeSubrange(range)

            print (predStr)
            
            stop.arrivals = predStr
            
            complete(predStr)
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

