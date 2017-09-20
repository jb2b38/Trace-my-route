//
//  ViewController.swift
//  Trace my route
//
//  Created by Jean-Baptiste de BERLHE on 20/09/2017.
//  Copyright © 2017 Jean-Baptiste de BERLHE. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

	@IBOutlet var map: MKMapView!
	let locationManager = CLLocationManager()
	var recording : Bool = false
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
			sender.title = "stop"
		default:
			map.showsUserLocation = false
			sender.title = "record"
		}
		
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
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
		
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		NSLog("New authorisation status : \(status)")
	}
	
}

