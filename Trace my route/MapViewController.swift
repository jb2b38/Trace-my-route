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
	@IBOutlet weak var trackingButton: MKUserTrackingBarButtonItem! {
		didSet {
			trackingButton.mapView = self.map;
		}
	}
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var distanceLabel: UILabel!
	var adView: GADBannerView!
	var mGoogleAdsConstraint: [AnyObject] = [AnyObject]()
	
	let locationManager = CLLocationManager()
	var recording : Bool = false
	var userCoordinates : Array<CLLocationCoordinate2D> = []
	var polylines : Array<MKPolyline> = []
	
	@IBAction func clearButtonPressed(_ sender: UIBarButtonItem) {
		userCoordinates.removeAll(keepingCapacity: false)
		for polyline in polylines {
			map.remove(polyline)
		}
		polylines.removeAll(keepingCapacity: false)
		updateDistanceLabel()
	}
	
	@IBAction func recordButtonPressed(_ sender: UIBarButtonItem) {
		
		recording = (sender.title! == "record")
		
		if recording {
			locationManager.startUpdatingHeading()
			locationManager.startUpdatingLocation()
			sender.title = "stop"
		} else {
			locationManager.stopUpdatingHeading()
			locationManager.stopUpdatingLocation()
			sender.title = "record"
		}
		
		map.showsUserLocation = recording
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		createGoogleAdBannerView()
		
		locationManager.requestWhenInUseAuthorization()
		
		locationManager.delegate = self
		locationManager.distanceFilter = 10
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
		
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
			polylines.removeFirst()
		}
	}
	
	func updateDistanceLabel() {
		
		guard let polyline = polylines.first else {
			distanceLabel.text = "0 km"
			return
		}
		
		if (polyline.pointCount > 1) {
			distanceLabel.text = String.localizedStringWithFormat("%.2f km", polyline.distance()/1000)
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
	
	func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
		return false
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		for location in locations {
			userCoordinates.append(location.coordinate)
		}
		
		let userTrace = MKPolyline(coordinates: userCoordinates, count: userCoordinates.count)
		setUserPolyline(polyline: userTrace)
		updateDistanceLabel()
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
		
		// mGoogleBannerView must be added as a subview before it can be used when creating constraints.
		view.addSubview(adView)
		
		let bannerHeight = adView.sizeThatFits(.zero).height
		
		//Every view fill their container (self.view) horizontally.
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[adView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["adView" : adView]))
		
		// Stack the map view atop the banner view. The result here is that moving the banner view will
		// resize the map view and the banner view will never overlap the map view.
		mGoogleAdsConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:[map][adView(==bannerHeight)]",
		                                                      options: NSLayoutFormatOptions(rawValue: 0),
		                                                      metrics: ["bannerHeight": bannerHeight],
		                                                      views: ["map": map, "adView": adView])
		view.addConstraints(mGoogleAdsConstraint as! [NSLayoutConstraint])
		
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

extension MKPolyline {
	var coordinates: [CLLocationCoordinate2D] {
		var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
		                                      count: self.pointCount)
		
		self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
		
		return coords
	}
	
	func distance() -> Double {
		var totalDistance: Double = 0
		
		for (index, element) in coordinates.enumerated() {
			if (index == (pointCount - 1)) {
				break
			}
			let currentPoint = CLLocation(latitude: element.latitude, longitude: element.longitude)
			let nextPoint = CLLocation(latitude: coordinates[index+1].latitude, longitude: coordinates[index+1].longitude)
			
			let currentDistance = currentPoint.distance(from: nextPoint)
			totalDistance += currentDistance
		}
		
		return totalDistance
	}
}
