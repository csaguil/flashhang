//
//  HTPushNotification.swift
//  HyperTrack
//
//  Created by Arjun Attam on 27/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

class PushNotificationService {

    static func registerForNotifications() {
        // Checks if user has given push notification
        // permissions to the app and saves
        // device token to settings
        let application = UIApplication.shared

        application.registerForRemoteNotifications()
    }
    
    static func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) {
        var token = ""

        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }

        Settings.setDeviceToken(deviceToken: token)
        PushNotificationService.registerDeviceToken()
    }
    
    static func didFailToRegisterForRemoteNotificationsWithError(error: Error) {
        debugPrint("Failed to register for notification: ", error.localizedDescription as Any)
    }
    
    static func registerDeviceToken() {
        // Called after the user has been set, so that
        // the device can be registered on the HyperTrack server
        
        let userId = Settings.getUserId()
        let device = UIDevice.current
        let deviceId = device.identifierForVendor?.uuidString
        var toRegister = true
        
        if let deviceToken = Settings.getDeviceToken(), let userId = Settings.getUserId() {
            if let registeredToken = Settings.getRegisteredToken() {
                if registeredToken == deviceToken {
                    toRegister = false
                }
            }
            
            if toRegister {
                let requestManager = RequestManager()
                
                requestManager.registerDeviceToken(userId: userId, deviceId: deviceId!, registrationId: deviceToken) { error in
                    if (error != nil) {
                        // Error in registering the token
                        debugPrint("Error registering device: ", error?.type.rawValue as Any)
                    } else {
                        // Successfully registered the token
                        Settings.setRegisteredToken(deviceToken: deviceToken)
                    }
                }
            }
        }
    }
    
    static func didReceiveRemoteNotification(userInfo: [AnyHashable:Any]) {
        if PushNotificationService.isHyperTrackNotification(userInfo: userInfo) {
            if let notificationUserId = userInfo["user_id"], let sdkUserId = Settings.getUserId() {
                let notificationUserIdString = notificationUserId as! String

                if sdkUserId == notificationUserIdString {
                    Transmitter.sharedInstance.updateSDKControls()
                    Transmitter.sharedInstance.flushCachedData()
                }
            }
            
        }
    }
    
    static func isHyperTrackNotification(userInfo: [AnyHashable:Any]) -> Bool {
        let key = "hypertrack_sdk_notification"
        return userInfo[key] != nil
    }
}
