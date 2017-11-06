//
//  CustomPushNotifications.swift
//  FirebaseFunction
//
//  Created by Sami Ali on 11/6/17.
//  Copyright © 2017 Sami Ali. All rights reserved.
//

import Foundation
import UserNotifications

func pushNotification(title: String, subtitle: String, body: String, soundOn: Bool){
    let notificationContent = UNMutableNotificationContent()
    // Configure Notification Content
    notificationContent.title = title
    notificationContent.subtitle = subtitle
    notificationContent.body = body
    if soundOn{
        notificationContent.sound = UNNotificationSound.default()
    }
    // Add Trigger
    let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
    
    // Create Notification Request
    let notificationRequest = UNNotificationRequest(identifier: "loca_beacon_notification", content: notificationContent, trigger: notificationTrigger)
    
    // Add Request to User Notification Center
    UNUserNotificationCenter.current().add(notificationRequest) { (error) in
        if let error = error {
            print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
        }
    }
}
