//
//  ViewController.swift
//  Trace my route
//
//  Created by Jean-Baptiste de BERLHE on 20/09/2017.
//  Copyright © 2017 Jean-Baptiste de BERLHE. All rights reserved.
//

import UIKit
import MapKit
import ASPolylineView

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

	@IBOutlet var map: MKMapView!
	@IBOutlet var clearButton: UIBarButtonItem!
	
	let locationManager = CLLocationManager()
	var recording : Bool = false
	var userCoordinates : Array<CLLocationCoordinate2D> = []
	var polylines : Array<MKPolyline> = []
	var isFirstLocation : Bool = true
	
	@IBAction func clearButtonPressed(_ sender: UIBarButtonItem) {
		userCoordinates.removeAll(keepingCapacity: false)
		for polyline in polylines {
			map.remove(polyline)
		}
		polylines.removeAll(keepingCapacity: false)
	}
	
	@IBAction func recordButtonPressed(_ sender: UIBarButtonItem) {
		if sender.title! == "record" {
			recording = true
		} else {
			recording = false
		}
		
		switch recording {
		case true:
			locationManager.requestAlwaysAuthorization()
			map.showsUserLocation = true
			isFirstLocation = true
			locationManager.startUpdatingHeading()
			locationManager.startUpdatingLocation()
			sender.title = "stop"
			
		default:
			map.showsUserLocation = false
			isFirstLocation = false
			locationManager.stopUpdatingHeading()
			locationManager.stopUpdatingLocation()
			sender.title = "record"
		}
		
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		map.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
	}
	
	func setUserPolyline(polyline: MKPolyline) {
		polylines.append(polyline)
		map.add(polyline)
		
		if (polylines.count > 1) {
			map.remove(polylines.first!)
			_ = polylines.dropFirst()
		}
	}
	
	func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
		
	}
	
	func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
		
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		NSLog("Location error : \(error)")
	}
	
	func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
		return false
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		if isFirstLocation {
			let region = MKCoordinateRegion(center: locations.last!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
			map.setRegion(region , animated: true)
			isFirstLocation = false
		}
		
		for location in locations {
			userCoordinates.append(location.coordinate)
		}
		
		let userTrace = MKPolyline(coordinates: userCoordinates, count: userCoordinates.count)
		setUserPolyline(polyline: userTrace)
		
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		NSLog("New authorisation status : \(status)")
	}
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		
		if overlay is MKPolyline {
			let renderer = ASPolylineRenderer(polyline: overlay as! MKPolyline)
			renderer.strokeColor = .red
			renderer.lineWidth = 12
			renderer.lineJoin = .round
			renderer.lineCap = .round
			renderer.borderColor = .white
			return renderer
		}
		return MKOverlayRenderer()
	}
	
	
}

