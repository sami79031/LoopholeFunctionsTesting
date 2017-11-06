//
//  AppDelegate.swift
//  FirebaseFunction
//
//  Created by Sami Ali on 11/3/17.
//  Copyright © 2017 Sami Ali. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, ESTBeaconManagerDelegate {

    var window: UIWindow?
    let beaconManager = ESTBeaconManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        self.beaconManager.delegate = self
        
        DispatchQueue.main.async {
            self.beaconManager.requestAlwaysAuthorization()
        }
        
        Messaging.messaging().delegate = self
        
        registerForPushNotifications()
        
        self.beaconManager.startMonitoring(for: CLBeaconRegion(
            proximityUUID: UUID(uuidString: "F86A4D73-485A-D73F-5F54-0A2776FF1498")!,
            major: 43285, minor: 2239, identifier: "Sami's beacon"))
        
        self.beaconManager.startMonitoring(for: CLBeaconRegion(
            proximityUUID: UUID(uuidString: "01E99038-A18B-5405-617F-3BA9EE68F0A7")!,
            major: 22843, minor: 10591, identifier: "Katia's beacon"))
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
         print("Firebase registration token: \(fcmToken)")
    }
    
    func beaconManager(_ manager: Any, didEnter region: CLBeaconRegion) {
        print("DID ENTER", region.identifier)
        pushNotification(title: region.identifier, subtitle: "Checked In", body: "", soundOn: true)
        userCheckedIn(region.identifier)
    }
    
    func beaconManager(_ manager: Any, didExitRegion region: CLBeaconRegion) {
        print("DID EXIT", region.identifier)
        pushNotification(title: region.identifier, subtitle: "Checked Out", body: "This is just the trigger to let you know that you are out of beacon range", soundOn: true)
        posiblCheckedOutUser(region.identifier)
    }

    func beaconManager(_ manager: Any, didDetermineState state: CLRegionState, for region: CLBeaconRegion) {
        if state.rawValue == 1 {
            print("User checked in")
        }else if state.rawValue == 2{
            print("User checked Out")
        }
    }
    
    func getPropertiesForRegion(region: CLBeaconRegion) -> (identifier: String, combinedKeys: String){
        let identifier = region.identifier
        var keys = ""
        if let major = region.major, let minor = region.minor {
            keys = "\(String(describing: major))\(String(describing: minor))"
        }
        
        return(identifier, keys)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                 UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
}

extension AppDelegate{
    
    func userCheckedIn(_ venueName: String){
        
        guard let userName = UserDefaults.standard.string(forKey: "kUSER_NAME"), let token = UserDefaults.standard.string(forKey: "kUSER_TOKEN") else {
            return
        }
        
        let refCheckedInVenue = firebase.child("CheckedInVenue").child(userName)
        let timeStamp = Date().millisecondsSince1970
        let readableTimeStamp = getDateInReadableFashion(timeStamp)
        let post = [
            "pushId" : token,
            "venueName" : venueName,
            "timestamp" : timeStamp,
            "readableTimeStamp" : readableTimeStamp
            ] as [String : Any]
        refCheckedInVenue.setValue(post) { (error, ref) in
            print("ERROR ", error?.localizedDescription ?? "nil")
        }
        
        let ref = firebase.child("PossiblyCheckedOut").child(userName)
        ref.setValue(nil)
    }
    
    
    func posiblCheckedOutUser(_ venueName: String) {
        guard let userName = UserDefaults.standard.string(forKey: "kUSER_NAME") else {
            return
        }
        
        let ref = firebase.child("PossiblyCheckedOut").child(userName)
        
        let timeStamp = Date().millisecondsSince1970
        let readableTimeStamp = getDateInReadableFashion(timeStamp)
        let post = [
            "venueName" : venueName,
            "timestamp" : timeStamp,
            "readableTimeStamp" : readableTimeStamp
            ] as [String : Any]
        
        ref.setValue(post) { (error, ref) in
            print("ERROR ", error?.localizedDescription ?? "")
        }
        
    }
    
    func dateFormatter()-> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MMMM-dd HH:mm:ss"
        return dateFormatter
    }
    
    func getDateInReadableFashion(_ timeStamp: Int)->String{
        let epocTime = TimeInterval(timeStamp) / 1000
        let date = Date(timeIntervalSince1970: epocTime)
        
        return dateFormatter().string(from: date)
    }
}
