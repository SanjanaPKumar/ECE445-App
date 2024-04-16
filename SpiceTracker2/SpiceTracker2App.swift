//
//  SpiceTracker2App.swift
//  SpiceTracker2
//
//  Created by Sanjana Kumar on 3/24/24.
//

import SwiftUI
import FirebaseCore
import GoogleMaps
import CoreLocation
import MapKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    FirebaseApp.configure()
    GMSServices.provideAPIKey("AIzaSyBGN9qq-PeNXScjoOSsyiYgkwEVFJSCHQc")
      
    //start region monitoring around the target right when the app finishes launching
  // Initialize your location manager and monitor a region
    LocationDataManager.shared.monitorRegionAtLocation(center: CLLocationCoordinate2D(latitude: 40.11035399200798, longitude: -88.23011653279755), identifier: "YourRegionIdentifier")
      
    registerForNotifications()
      
    //Request user permissions
    func registerForNotifications() {
      UNUserNotificationCenter.current()
          .requestAuthorization(options: [.alert]) {
              granted, error in
              print("Permission granted: \(granted)")
              }
      }
    //registration callback functions to check whether the registration fails or succeeds and display the notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
              completionHandler([.banner])
          }
    
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
          // set notificationTapped to true in the main app's state
          if let rootViewController = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
              if let app = rootViewController.viewControllers.first as? YourApp {
                  app.notificationTapped = true
              }
          }
          
          completionHandler()
      }
            
    return true
  }
}

//Handling a region-entered notification
func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
   if let region = region as? CLCircularRegion {
       let identifier = region.identifier
       triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
   }
}

//next actions for when phone enters region
func triggerTaskAssociatedWithRegionIdentifier(regionID: String) {
        // Handle tasks associated with entering the region
    }

@main
struct YourApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var notificationTapped: Bool = false
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                        if notificationTapped {
//                            ContentView.currentPage = .groceryPage
                        }
                    }
                // Check if notificationTapped is true and reset it
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                        if let _ = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
                            self.notificationTapped = true
                        }
                    }
            }
        }
    }
}

