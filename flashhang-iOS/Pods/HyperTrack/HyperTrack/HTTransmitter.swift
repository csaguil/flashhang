//
//  HTTransmitter.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 23/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import Alamofire
import XCGLogger

let logger: XCGLogger = {
    
    let logger = XCGLogger(identifier: "HyperTrackLogger", includeDefaultDestinations: false)
    let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
    if let path = paths.first {
        let logPath = URL(fileURLWithPath: path.appending("/HyperTrack_Log.txt"), isDirectory: true)
        logger.setup(level: .debug, writeToFile: logPath, fileLevel: .debug)
    }
    let systemDestination = AppleSystemLogDestination(identifier: "HyperTrackLogger.systemDestination")
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true
    logger.add(destination: systemDestination)
    return logger
    
}()

final class Transmitter {
    static let sharedInstance = Transmitter()
    var delegate:HyperTrackDelegate? = nil
    let locationManager:LocationManager
    let mockLocationManager:MockLocationManager

    let requestManager: RequestManager
    var ttlTimer: Timer?
    
    var isTracking:Bool {
        get {
            return self.locationManager.isTracking
        }
    }
    
    var isMockTracking:Bool {
        get {
            return self.mockLocationManager.isTracking
        }
    }
    
    init() {
        self.locationManager = LocationManager()
        EventsDatabaseManager.sharedInstance.createEventsTable()
        self.requestManager = RequestManager()
        self.mockLocationManager = MockLocationManager()
    }
    
    func initialize() {
        if self.isTracking {
            self.startTracking(completionHandler: nil)
        }
    }
    
    func sync() {
        let isTracking = Settings.getTracking()
        if isTracking {
            self.startTracking(completionHandler: nil)
        }
    }
    
    func setUserId(userId:String) {
        Settings.setUserId(userId: userId)
        PushNotificationService.registerDeviceToken()
    }
    
    func getUserId() -> String? {
        return Settings.getUserId()
    }
    
    func createUser(_ name:String, completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        self.requestManager.createUser(["name":name]) { user, error in
            
            if (user != nil) {
                self.setUserId(userId: (user?.id)!)
            } else if (error != nil) {
                debugPrint("Error creating user: ", error?.type.rawValue as Any)
            }
            
            if (completionHandler != nil) {
                completionHandler!(user, error)
            }
        }
    }
    
    func createUser(_ name: String, _ phone: String, _ photo: UIImage?, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        if let photo = photo {
            //Do image upload here, can't pass UIImage directly
        }
        
        self.requestManager.createUser(["name": name, "phone": phone]) { user, error in
            
            if (user != nil) {
                self.setUserId(userId: (user?.id)!)
            } else if (error != nil) {
                debugPrint("Error creating user: ", error?.type.rawValue as Any)
            }
            
            completionHandler(user, error)
        }
    }
    
    func createUser(_ name: String, _ phone: String, _ lookupID: String, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        
        self.requestManager.createUser(["name": name, "phone": phone, "lookup_id": lookupID]) { user, error in
            if (user != nil) {
                self.setUserId(userId: (user?.id)!)
                Settings.setLookupId(lookupId: lookupID)
            } else if (error != nil) {
                debugPrint("Error creating user: ", error?.type.rawValue as Any)
            }
            
            completionHandler(user, error)
        }
    }
    
    
    func setPublishableKey(publishableKey:String) {
        Settings.setPublishableKey(publishableKey: publishableKey)
    }
    
    func getPublishableKey() -> String? {
        return Settings.getPublishableKey()
    }
    
    func canStartTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) -> Bool {
        // Allow Background Location updates
        self.locationManager.allowBackgroundLocationUpdates()
        
        if (Settings.getUserId() == nil) {
            debugPrint("Can't start tracking. Need userId.")
            let error = HyperTrackError(HyperTrackErrorType.userIdError)
            delegate?.didFailWithError(error)
            
            guard let completionHandler = completionHandler else { return false }
            completionHandler(error)
            return false
        } else if (Settings.getPublishableKey() == nil) {
            debugPrint("Can't start tracking. Need publishableKey.")
            let error = HyperTrackError(HyperTrackErrorType.publishableKeyError)
            delegate?.didFailWithError(error)
            
            guard let completionHandler = completionHandler else { return false }
            completionHandler(error)
            return false
        }
        
        return true
    }
    
    func startTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
        if !canStartTracking(completionHandler: completionHandler) {
            return
        }
        
        if isMockTracking {
            // If you start tracking when mocking is active,
            // the mocking gets stopped
            stopMockTracking()
        }
        
        self.locationManager.startPassiveTrackingService()
        
        guard let completionHandler = completionHandler else { return }
        completionHandler(nil)
    }
    
    func startMockTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
        if !canStartTracking(completionHandler: completionHandler) {
            return
        }
        
        if isTracking {
            // If tracking is active, the mock tracking will
            // not continue and throw an error.
            guard let completionHandler = completionHandler else { return }
            let error = HyperTrackError(HyperTrackErrorType.invalidParamsError)
            completionHandler(error)
            return
        }
        
        var originLatlng:String = ""
        
        if let location = locationManager.getLastKnownLocation() {
            originLatlng = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        } else {
            originLatlng = "28.556446,77.174095"
        }
        
        self.requestManager.getSimulatePolyline(originLatlng: originLatlng) { (polyline, error) in
            if let error = error {
                debugPrint("Error simulating:", error.type.rawValue)
                
                guard let completionHandler = completionHandler else { return }
                completionHandler(error)
                return
            }
            if let polyline = polyline {
                let decoded = timedCoordinatesFrom(polyline: polyline)
                // Mock location manager maintains a request manager
                // and converts these locations into events
                self.mockLocationManager.startService(coordinates: decoded!)
            }
        }
    }
    
    func stopMockTracking() {
        mockLocationManager.stopService()
    }
    
    func stopTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
        self.locationManager.stopPassiveTrackingService()
        
        if (completionHandler != nil) {
            completionHandler!(nil)
        }
    }
    
    func getAction(_ actionId: String, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        self.requestManager.getAction(actionId) { action, error in
            if let action = action {
                completionHandler(action, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func createAndAssignAction(_ actionParams:HyperTrackActionParams, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        
        var action = [
            "user_id": Settings.getUserId() as Any,
            "type": actionParams.type as Any,
            "expected_at": actionParams.expectedAt as Any,
            "lookup_id":actionParams.lookupId as Any
            ] as [String: Any]
        
        if let expectedPlace = actionParams.expectedPlace {
            action["expected_place"] = expectedPlace.toDict() as Any
        }
        else if let expectedPlaceID = actionParams.expectedPlaceId {
            action["expected_place_id"] = expectedPlaceID as Any
        }else{
            completionHandler(nil,HyperTrackError(HyperTrackErrorType.invalidParamsError))
            return
        }
        
        if let currentLocation = Settings.getLastKnownLocation() {
            currentLocation.recordedAt = Date()
            action["current_location"] = currentLocation.toDict()
        }
        
        self.requestManager.assignAction(action) { action, error in
            if let action = action {
                completionHandler(action, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func completeAction(actionId: String?) {
        guard let userId = self.getUserId() else { return }
        
        guard let actionId = actionId else {
            let event = HyperTrackEvent(userId: userId, recordedAt: Date(), eventType: "action.completed", location: Settings.getLastKnownLocation())
            event.save()
            self.requestManager.postEvents()
            return
        }
        
        let event = HyperTrackEvent(userId: userId, recordedAt: Date(), eventType: "action.completed", location: Settings.getLastKnownLocation(), data: ["action_id": actionId])
        event.save()
        self.requestManager.postEvents()
    }
    
    func cancelPendingActions(completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        guard let userId = self.getUserId() else {
            if let completion = completionHandler {
                completion(nil, HyperTrackError.init(HyperTrackErrorType.invalidParamsError))
            }
            return
        }
        
        self.requestManager.cancelActions(userId: userId, completionHandler: completionHandler)
    }
    
    func updateSDKControls() {
        guard let userId = self.getUserId() else { return }
        
        self.requestManager.getSDKControls(userId: userId) { (controls, error) in
            if (error == nil) {
                if let controls = controls {
                    self.processSDKControls(controls: controls)
                }
            } else {
                debugPrint("Error getting controls: ", error?.type.rawValue as Any)
            }
        }
    }
    
    func refreshTransmitter() {
        // Get new controls and recreate transmitter timers
        let (batchDuration, minimumDisplacement) = HyperTrackSDKControls.getControls()
        
        // TODO: abstract this for location manager and mock location manager
        locationManager.updateRequestTimer(batchDuration: batchDuration)
        locationManager.updateLocationManager(filterDistance: minimumDisplacement)
    }
    
    @objc func resetTransmitter() {
        // Reset transmitter to default controls
        // Clear controls from settings
        HyperTrackSDKControls.clearSavedControls()
        self.refreshTransmitter()
    }

    func processSDKControls(controls: HyperTrackSDKControls) {
        // Process controls
        if let runCommand = controls.runCommand {

            if runCommand == "GO_OFFLINE" {
                // Stop tracking from the backend
                if self.isTracking {
                    HyperTrack.stopTracking()
                }
            } else if runCommand == "FLUSH" {
                self.flushCachedData()
            } else if runCommand == "GO_ACTIVE" {
                // nothing to do as controls will handle
            } else if runCommand == "GO_ONLINE" {
                // nothing to do as controls will handle
            }
        }
        
        if let ttl = controls.ttl {
            
            if ttl > 0 {
                // Handle ttl and set a timer that will
                // reset to defaults
                if (self.ttlTimer != nil) {
                    self.ttlTimer?.invalidate()
                }
                
                self.ttlTimer = Timer.scheduledTimer(timeInterval: Double(ttl),
                                                     target: self,
                                                     selector: #selector(self.resetTransmitter),
                                                     userInfo: nil,
                                                     repeats: false);
            }
        }
        
        HyperTrackSDKControls.saveControls(controls: controls)
        refreshTransmitter()
    }
    
    func flushCachedData() {
        self.requestManager.postEvents(flush: true)
    }
    
    // Utility methods
    func requestWhenInUseAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func requestMotionAuthorization() {
        self.locationManager.requestMotionAuthorization()
    }
    
    func callDelegateWithEvent(event: HyperTrackEvent) {
        delegate?.didReceiveEvent(event)
    }
    
    func callDelegateWithError(error: HyperTrackError) {
        delegate?.didFailWithError(error)
    }
}
