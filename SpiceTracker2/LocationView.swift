//
//  LocationView.swift
//  SpiceTracker2
//
//  Created by Nynika Badam on 4/1/24.
//

import GoogleMaps
import CoreLocation
import SwiftUI
import MapKit

//var currentLocation: CLLocation? // Declare currentLocation as a published property
//init(latitude: CLLocationDegrees, longitude: CLLocationDegrees)

// Creates a location data manager.
//central access point to all location services; start and stop the services you use

//need to add stipulation that location services are only enabled when there's ingredients in the grocery list -> communicate with ContentView and Firebase

@MainActor
class LocationDataManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationDataManager()
        
    // Create a location manager.
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation? // Declare currentLocation as a published property
    
    override init() {
        super.init()
        
    // Inspect the location manager's authorization status.
    switch locationManager.authorizationStatus {


        // If authorized, start location services.
    case .authorizedWhenInUse:
        startUpdatingLocationAndHeading()


        // Request authorization if the user hasn't chosen whether your app
        // can use location services yet.
    case .notDetermined:
        locationManager.requestWhenInUseAuthorization()


    case .denied, .restricted:
        // Handle denied or restricted status.
        break
    default:
        break
    }
        
        // Configure the location manager.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    // Location-related properties and methods.
    func startUpdatingLocationAndHeading() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        }
    
    //Monitoring a region around the specified coordinate
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String ) {
        // Make sure the devices supports region monitoring.
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            let maxDistance = locationManager.maximumRegionMonitoringDistance
            let region = CLCircularRegion(center: center,
                 radius: maxDistance, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = false
       
            locationManager.startMonitoring(for: region)
            
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates here
        guard let location = locations.last else { return }
        print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Do something with the location data
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location manager errors here
        print("Location manager failed with error: \(error)")
    }
    
    // Additional methods for handling location updates and errors

}

