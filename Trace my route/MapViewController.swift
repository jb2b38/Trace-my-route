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
import GoogleMobileAds

class MapViewController:
	UIViewController,
	MKMapViewDelegate {

	@IBOutlet var map: MKMapView!
	@IBOutlet var clearButton: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	var adView: GADBannerView!
	var mGoogleAdsConstraint: [AnyObject] = [AnyObject]()
	
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
		
		recording = (sender.title! == "record")
		
		if recording {
			locationManager.requestWhenInUseAuthorization()
			locationManager.startUpdatingHeading()
			locationManager.startUpdatingLocation()
			sender.title = "stop"
		} else {
			locationManager.stopUpdatingHeading()
			locationManager.stopUpdatingLocation()
			sender.title = "record"
		}
		
		map.showsUserLocation = recording
		isFirstLocation = recording
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		createGoogleAdBannerView()
		
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

extension MapViewController: CLLocationManagerDelegate {
	
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
}

extension MapViewController: GADBannerViewDelegate {
	
	func createGoogleAdBannerView() {
		adView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
		adView.adUnitID = "ca-app-pub-6559718590786776/7973989603"
		
		adView.translatesAutoresizingMaskIntoConstraints = false
		adView.delegate = self
		
		// mGoogleBannerView must be added as a subview before it can be used when creating
		// constraints.
		view.addSubview(adView)
		
		// Get rid of all existing constraints that were defined in the storyboard.
		// Alternatively, you could create the banner view and all of these constraints
		// in the storyboard.
		view.removeConstraints(view.constraints)
		
		let bannerHeight = adView.sizeThatFits(.zero).height
		
		//Every view fill their container (self.view) horizontally.
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[map]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["map": map]))
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[toolbar]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["toolbar": toolbar]))
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[adView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["adView" : adView]))
		
		// Stack the map view atop the banner view and pin the top of the map view
		// to the container top.  The result here is that moving the banner view will
		// resize the map view and the banner view will never overlap the map view.
		mGoogleAdsConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|[map][adView(==bannerHeight)]",
		                                                      options: NSLayoutFormatOptions(rawValue: 0),
		                                                      metrics: ["bannerHeight": bannerHeight],
		                                                      views: ["map": map, "adView": adView])
		view.addConstraints(mGoogleAdsConstraint as! [NSLayoutConstraint])
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[toolbar]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["toolbar" : toolbar]))
		
		// Finally, place the banner view (bannerHeight) points below the toolbar (ofscreen).
		// Because of the constraint above, the map view will now fill the container but we
		// will adjust this constraint later to hide and show the banner.
		view.addConstraint(NSLayoutConstraint(item: adView, attribute: .bottom, relatedBy: .equal, toItem: toolbar, attribute: .top, multiplier: 1, constant: bannerHeight))
		
		// Let the runtime know which UIViewController to restore after taking
		// the user wherever the ad goes and add it to the view hierarchy.
		adView.rootViewController = self
		
		// Initiate a generic request to load it with an ad.
		let request = GADRequest()
		request.testDevices = [kGADSimulatorID, "1411665598671159fe543ab12fbbb03f"]
		adView.load(request)
		
		view.bringSubview(toFront: toolbar) //Prevents adview from hiding the toolbar behind it.
	}
	
	func adjustBannerView(adLoaded: Bool) {
		
		// Find the constraint that pins mBannerView to the bottom of its container.
		// See the last line of -createAdBannerView.
		var bannerViewBottomConstraint: NSLayoutConstraint!
		for constraint in view.constraints {
			if (constraint.firstItem as? GADBannerView == adView) && (constraint.secondItem as? UIToolbar == toolbar) {
				bannerViewBottomConstraint = constraint
			}
		}
		
		let bannerHeight = adView.sizeThatFits(.zero).height
		
		UIView.animate(withDuration: 0.3) {
			if adLoaded {
				// A value of 0 means the bottom of the banner view will be equal
				// to the bottom of its container, so the banner view will be visible.
				bannerViewBottomConstraint.constant = 0
			} else {
				// Positive value pushes it down.  A positive value of bannerHeight
				// pushes it offscreen.
				bannerViewBottomConstraint.constant = bannerHeight
			}
			
			// Force a layout while in the animation block so the view's frames
			// actually are modified according to the new constraints.
			self.view.setNeedsLayout()
			self.view.layoutIfNeeded()
		}
	}
	
	func adViewDidReceiveAd(_ bannerView: GADBannerView) {
		adjustBannerView(adLoaded: true)
	}
	
	func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
		adjustBannerView(adLoaded: false)
	}
}
