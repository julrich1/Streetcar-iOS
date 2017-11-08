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
var STREETCAR_SELECTED_IMAGE: UIImage?

var STOP_IMAGE: UIImage?
var STOP_SELECTED_IMAGE: UIImage?

var carAnimation = ARCarMovement()

var selectedItem = (id: 0, type: "")

class ViewController: UIViewController, GMSMapViewDelegate {
    @IBOutlet weak var mapContainerView: GMSMapView!
    @IBOutlet var bottomStopPanel: BottomPanelStop!
    @IBOutlet var bottomStreetcarPanel: BottomPanelStreetcar!
    
    @IBOutlet weak var gestureScreenEdgePan: UIScreenEdgePanGestureRecognizer!
    @IBOutlet weak var viewBlack: UIView!
    @IBOutlet weak var viewMenu: UIView!
    @IBOutlet weak var constraintMenuLeft: NSLayoutConstraint!
    @IBOutlet weak var constraintMenuWidth: NSLayoutConstraint!
    
//    @IBOutlet weak var fhsRoute: UIButton!
//    @IBOutlet weak var sluRoute: UIButton!
    var polylines = [GMSPolyline]()
    
    var route = 1
    
    let maxBlackViewAlpha: CGFloat = 0.5
    let animationDuration: TimeInterval = 0.3
    var isLeftToRight = true
    
    var urlSession = URLSession.shared

    
//    override func loadView() {
//        let camera = GMSCameraPosition.camera(withLatitude: 47.605403, longitude: -122.320826, zoom: 15.0)
//        map = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
//        map.delegate = self
//
//        view = map
////        self.view.addSubview(map)
////        self.view.insertSubview(map, at: 0)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hamburger Menu
        constraintMenuLeft.constant = -constraintMenuWidth.constant
        
        viewBlack.alpha = 0
        viewBlack.isHidden = true
        
        let language = NSLocale.preferredLanguages.first!
        let direction = NSLocale.characterDirection(forLanguage: language)
        
        if direction == .leftToRight {
            gestureScreenEdgePan.edges = .left
            isLeftToRight = true
        }
        else {
            gestureScreenEdgePan.edges = .right
            isLeftToRight = false
        }
        
        map = mapContainerView
        
        let camera = GMSCameraPosition.camera(withLatitude: 47.609809, longitude: -122.320826, zoom: 15.0)
        
        map.moveCamera(GMSCameraUpdate.setCamera(camera))
        map.delegate = self
        
        self.view.addSubview(map!)
        self.view.sendSubview(toBack: map)
        
        STREETCAR_IMAGE = UIImage(named: "streetcar")!.withRenderingMode(.alwaysTemplate)
        STREETCAR_SELECTED_IMAGE = UIImage(named: "streetcar_selected")!.withRenderingMode(.alwaysTemplate)
        
        STOP_IMAGE = UIImage(named: "stop_icon")!.withRenderingMode(.alwaysTemplate)
        STOP_SELECTED_IMAGE = UIImage(named: "stop_selected_icon")!.withRenderingMode(.alwaysTemplate)
        
        getStops()
        startTimers()
    }
    
    func startTimers() {
        updateStreetcars()
        scTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateStreetcars), userInfo: nil, repeats: true)
    }
    
    func removeSelectedIcon() {
        if selectedItem.type == "streetcar" {
            let sc = streetcars.findStreetcarById(id: selectedItem.id)
            if sc != nil {
                let streetC = sc as! Streetcar
                streetC.marker?.icon = STREETCAR_IMAGE
            }
        }
        else if selectedItem.type == "stop" {
            for stop in stops {
                if stop.stopId == selectedItem.id {
                    stop.marker?.icon = STOP_IMAGE
                }
            }
        }
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("Clicked a marker")

        let id = (marker.userData as! MarkerData).id

        if id != selectedItem.id {
            removeSelectedIcon()
        }

        if ((marker.userData as! MarkerData).type == "streetcar") {
            selectedItem = (id: id as Int, type: "streetcar")
            marker.icon = STREETCAR_SELECTED_IMAGE
            bottomStopPanel.hide()
            bottomStreetcarPanel.show()
            
            let streetcar = streetcars.findStreetcarById(id: id)
            
            if (streetcar != nil) {
                let sc = streetcar as! Streetcar
                
                self.bottomStreetcarPanel.showStreetcar(idle: sc.idle, speed: streetcars.convertKmHrToMph(speed: sc.speedkmhr), location: "\(sc.x) \(sc.y)")
            }
        }
        else if ((marker.userData as! MarkerData).type == "stop") {
            selectedItem = (id: id as Int, type: "stop")
            marker.icon = STOP_SELECTED_IMAGE
            bottomStreetcarPanel.hide()
            bottomStopPanel.show()
            
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
        removeSelectedIcon()
        selectedItem = (id: 0, type: "")
        hideMenu()
        bottomStopPanel.hide()
        bottomStreetcarPanel.hide()
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
            marker.icon = STREETCAR_IMAGE
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
            marker.icon = STOP_IMAGE
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
                carAnimation.ARCarMovement(marker: streetcar.marker!, oldCoordinate: streetcar.marker!.position, newCoordinate: CLLocationCoordinate2D(latitude: streetcar.x, longitude: streetcar.y), mapView: map, bearing: Float(streetcar.heading))
//                streetcar.marker?.position = CLLocationCoordinate2D(latitude: streetcar.x, longitude: streetcar.y)
//                streetcar.marker?.rotation = CLLocationDegrees(streetcar.heading)
            }
        }
    }
    
    func getStops() {
        let url = URL(string: "http://sc-dev.shadowline.net/api/routes/" + String(route))

        urlSession.dataTask(with:url!, completionHandler: {(data, response, error) in
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
        var routeStr: String
        
        if route == 1 {
            routeStr = "FHS"
        }
        else {
            routeStr = "SLU"
        }
        
        let url = URL(string: "http://webservices.nextbus.com/service/publicJSONFeed?command=predictions&a=seattle-sc&r=" + routeStr + "&s=\(stop.stopId)")
        
        urlSession.dataTask(with:url!, completionHandler: {(data, response, error) in
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
            
            self.polylines.append(polyline)
        }
    }
    
    func removePolyLines() {
        for polyline in polylines {
            polyline.map = nil
        }
        
        polylines.removeAll(keepingCapacity: false)
    }
    
    func removeStops() {
        for stop in stops {
            stop.marker?.map = nil
        }
        
        stops.removeAll(keepingCapacity: false)
    }
    
    @objc func updateStreetcars() {
        let url = URL(string: "http://sc-dev.shadowline.net/api/streetcars/" + String(route))
        print ("updateStreetcars() called")
        urlSession.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]
                print ("Response received for streetcars, updating the array!")
                streetcars.updateStreetcars(scObject: jsonArray)
                self.updateMarkers();
            } catch let error as NSError {
                print(error)
            }
        }).resume()
    }

    @IBAction func gestureScreenEdgePan(_ sender: UIScreenEdgePanGestureRecognizer) {
        print("Gesturescreenedgepan called")
        // retrieve the current state of the gesture
        if sender.state == UIGestureRecognizerState.began {
            
            // if the user has just started dragging, make sure view for dimming effect is hidden well
            viewBlack.isHidden = false
            viewBlack.alpha = 0
            
        } else if (sender.state == UIGestureRecognizerState.changed) {
            
            // retrieve the amount viewMenu has been dragged
            var translationX = sender.translation(in: sender.view).x
            
            if !isLeftToRight {
                translationX = -translationX
            }
            
            if -constraintMenuWidth.constant + translationX > 0 {
                
                // viewMenu fully dragged out
                constraintMenuLeft.constant = 0
                viewBlack.alpha = maxBlackViewAlpha
                
            } else if translationX < 0 {
                
                // viewMenu fully dragged in
                constraintMenuLeft.constant = -constraintMenuWidth.constant
                viewBlack.alpha = 0
                
            } else {
                
                // viewMenu is being dragged somewhere between min and max amount
                constraintMenuLeft.constant = -constraintMenuWidth.constant + translationX
                
                let ratio = translationX / constraintMenuWidth.constant
                let alphaValue = ratio * maxBlackViewAlpha
                viewBlack.alpha = alphaValue
            }
        } else {
            
            // if the menu was dragged less than half of it's width, close it. Otherwise, open it.
            if constraintMenuLeft.constant < -constraintMenuWidth.constant / 2 {
                self.hideMenu()
            } else {
                self.openMenu()
            }
        }
    }
    
    @IBAction func gesturePan(_ sender: UIPanGestureRecognizer) {
        print ("Gesturepan called")
        // retrieve the current state of the gesture
        if sender.state == UIGestureRecognizerState.began {
            
            // no need to do anything
        } else if sender.state == UIGestureRecognizerState.changed {
            
            // retrieve the amount viewMenu has been dragged
            var translationX = sender.translation(in: sender.view).x
            
            if !isLeftToRight {
                translationX = -translationX
            }
            
            if translationX > 0 {
                
                // viewMenu fully dragged out
                constraintMenuLeft.constant = 0
                viewBlack.alpha = maxBlackViewAlpha
                
            } else if translationX < -constraintMenuWidth.constant {
                
                // viewMenu fully dragged in
                constraintMenuLeft.constant = -constraintMenuWidth.constant
                viewBlack.alpha = 0
                
            } else {
                
                // it's being dragged somewhere between min and max amount
                constraintMenuLeft.constant = translationX
                
                let ratio = (constraintMenuWidth.constant + translationX) / constraintMenuWidth.constant
                let alphaValue = ratio * maxBlackViewAlpha
                viewBlack.alpha = alphaValue
            }
        } else {
            
            // if the drag was less than half of it's width, close it. Otherwise, open it.
            if constraintMenuLeft.constant < -constraintMenuWidth.constant / 2 {
                self.hideMenu()
            } else {
                self.openMenu()
            }
        }
    }
    
    @IBAction func gestureTap(_ sender: UITapGestureRecognizer) {
        self.hideMenu()
    }
    
    @IBAction func buttonHamburger() {
        if constraintMenuLeft.constant == -constraintMenuWidth.constant {
            self.openMenu()
        }
        else if constraintMenuLeft.constant == 0 {
            self.hideMenu()
        }
    }
    
    func openMenu() {
        print("Openmenu called")
        // when menu is opened, it's left constraint should be 0
        constraintMenuLeft.constant = 0
        
        // view for dimming effect should also be shown
        viewBlack.isHidden = false
        
        // animate opening of the menu - including opacity value
        UIView.animate(withDuration: animationDuration, animations: {
            
            self.view.layoutIfNeeded()
            self.viewBlack.alpha = self.maxBlackViewAlpha
            
        }, completion: { (complete) in
            
            // disable the screen edge pan gesture when menu is fully opened
            self.gestureScreenEdgePan.isEnabled = false
        })
    }
    
    func hideMenu() {
        print ("Hidemenu called")
        // when menu is closed, it's left constraint should be of value that allows it to be completely hidden to the left of the screen - which is negative value of it's width
        constraintMenuLeft.constant = -constraintMenuWidth.constant
        
        // animate closing of the menu - including opacity value
        UIView.animate(withDuration: animationDuration, animations: {
            
            self.view.layoutIfNeeded()
            self.viewBlack.alpha = 0
            
        }, completion: { (complete) in
            
            // reenable the screen edge pan gesture so we can detect it next time
            self.gestureScreenEdgePan.isEnabled = true
            
            // hide the view for dimming effect so it wont interrupt touches for views underneath it
            self.viewBlack.isHidden = true
        })
    }

    @IBAction func fhsRouteAction() {
        print("Change route")
        route = 1
        swapViews(lat: 47.609809, lon: -122.320826)
        getStops()
    }

    @IBAction func sluRouteAction() {
        print("Change route")
        route = 2
        swapViews(lat: 47.621358, lon: -122.338190)
        getStops()
    }
    
    func swapViews(lat: Double, lon: Double) {
        scTimer?.invalidate()
        
        urlSession.getAllTasks { tasks in
            for task in tasks {
                task.cancel()
                print("Cancelling task: ", task)
            }
        }

        hideMenu()
        bottomStopPanel.hide()
        bottomStreetcarPanel.hide()
        
        streetcars.removeStreetcars()
        removePolyLines()
        removeStops()
        
        startTimers()
        
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lon, zoom: 15.0)
        map.moveCamera(GMSCameraUpdate.setCamera(camera))
    }
}

