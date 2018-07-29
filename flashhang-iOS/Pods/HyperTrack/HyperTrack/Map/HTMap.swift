//
//  HTMap.swift
//  HyperTrack
//
//  Created by Anil Giri on 26/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

/**
 Enum for multiple map providers.
 */
public enum HTMapProvider {
    /**
     Apple maps
     */
    case appleMaps
    
    /**
     Google maps
     */
    case googleMaps
    
    /**
     Open street maps
     */
    case openStreetMaps
}

/**
 The HyperTrack map object. Use the shared instance of this to set interaction and customization delegates, and embed your view object.
 */
@objc public final class HTMap: NSObject, ActionStoreDelegate, HTViewInteractionInternalDelegate {
    
    static let sharedInstance = HTMap()
    var baseMapProvider: HTMapProvider
    var mapProvider: MapProviderProtocol?
    var mapView: MKMapView!
    var phoneNumber: String? = nil
    
    var view: HTView!
    var interactionDelegate: HTViewInteractionDelegate?
    var customizationDelegate: HTViewCustomizationDelegate?
    
    var lastPlottedTime = Date.distantPast
    var lastPosition: CLLocationCoordinate2D?
    var destination: CLLocationCoordinate2D?
    
    var isAddressViewShown: Bool = true
    var isInfoViewShown: Bool = true
    var isRefocusButtonShown: Bool = true
    var isBackButtonShown: Bool = true
    var initialCoordinates: CLLocationCoordinate2D =
        CLLocationCoordinate2DMake(28.5621352, 77.1604902)
    
    convenience override init() {
        // Default map is Apple Maps
        self.init(baseMap: HTMapProvider.appleMaps,initialRegion: MKCoordinateRegionMake(
            CLLocationCoordinate2DMake(28.5621352, 77.1604902),
            MKCoordinateSpanMake(0.005, 0.005)))
    }
    
    init(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        baseMapProvider = baseMap
        super.init()
        setupViewForProvider(baseMap: self.baseMapProvider, initialRegion: initialRegion)
    }
    
    /** 
     Use this method on the shared instance of the Map object, to embed the map inside your UIView object.
     
     - Parameter parentView: The UIView object that embeds the map.
     */
    public func embedIn(_ parentView: UIView) {
        self.view.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.height)
        // translate to fix height of the mapView
        parentView.translatesAutoresizingMaskIntoConstraints = true
        
        self.mapView.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.size.height)
        parentView.addSubview(self.view)
    }
    
    /**
     Method to set the customization delegate
     
     - Parameter customizationDelegate: Object conforming to HTViewCustomizationDelegate
     */
    public func setHTViewCustomizationDelegate(customizationDelegate: HTViewCustomizationDelegate) {
        self.customizationDelegate = customizationDelegate
        
        if let initialCoordinates: CLLocationCoordinate2D = self.customizationDelegate?.initialCoordinatesFor?(map: self) {
            self.initialCoordinates = initialCoordinates
        }
        
        // HACK to enable map reload after setHTViewCustomizationDelegate()
        self.setupViewForProvider(baseMap: self.baseMapProvider, initialRegion:
            MKCoordinateRegionMake(self.initialCoordinates,
                                   MKCoordinateSpanMake(0.005, 0.005)))
    }
    
    /**
     Method to set the interaction delegate
     
     - Parameter interactionDelegate: Object conforming to HTViewInteractionDelegate
     */
    public func setHTViewInteractionDelegate(interactionDelegate: HTViewInteractionDelegate) {
        self.interactionDelegate = interactionDelegate
    }
    
    /**
     Method to remove the map from the parent view
     
     - Parameter parentView: UIView where map has been embedded
     */
    public func removeFromView(_ parentView:UIView) {
        
        if (self.view.isDescendant(of: parentView)) {
            self.view.removeFromSuperview()
        } else {
            print("Failed::Tried to remove mapview from a view that it is not a child of.")
        }
    }
    
    /**
     Method to clear actions from the map
     */
    public func clearAction() {
        // Clear action, which would clear the marker and
        // HTView UI elements
        self.mapProvider?.clearMap()
    }
    
    func trackActionFor(actionID: String) {
        ActionStore.sharedInstance.trackActionFor(actionID, delegate: self)
    }
    
    func trackActionFor(shortCode: String) {
        ActionStore.sharedInstance.trackActionFor(shortCode: shortCode, delegate: self)
    }
    
    // ViewInteractionDelegate Methods
    
    internal func didTapReFocusButton(_ sender: Any, isInfoViewCardExpanded: Bool) {
        self.mapProvider?.reFocusMap(isInfoViewCardExpanded: isInfoViewCardExpanded)
        self.interactionDelegate?.didTapReFocusButton?(sender, isInfoViewCardExpanded: isInfoViewCardExpanded)
    }
    
    internal func didTapBackButton(_ sender: Any) {
        self.interactionDelegate?.didTapBackButton?(sender)
    }
    
    internal func didTapPhoneButton(_ sender: Any) {
        if let phoneNumber = self.phoneNumber {
            let phoneUrl = URL(string: "tel:" + phoneNumber)
            UIApplication.shared.openURL(phoneUrl!)
        }
        self.interactionDelegate?.didTapPhoneButton?(sender)
    }
    
    internal func didTapHeroMarkerFor(userID: String) {
        self.interactionDelegate?.didTapHeroMarkerFor?(userID: userID)
    }
    
    internal func didTapExpectedPlaceMarkerFor(actionID: String) {
        self.interactionDelegate?.didTapExpectedPlaceMarkerFor?(actionID: actionID)
    }
    
    internal func didTapInfoViewFor(actionID: String) {
        self.interactionDelegate?.didTapInfoViewFor?(actionID: actionID)
    }
    
    internal func didTapMapView() {
        self.interactionDelegate?.didTapMapView?()
    }
    
    internal func didPanMapView() {
        self.interactionDelegate?.didPanMapView?()
    }
    
    // MARK Private
    func setupViewForProvider(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        self.mapView = getMapView()
        initHTView(mapView: mapView)
        
        self.mapProvider = self.providerFor(baseMap)
        self.mapProvider?.zoomTo(visibleRegion: initialRegion, animated: true)
        self.mapProvider?.mapInteractionDelegate = self
    }
    
    func getMapView() -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = false
        mapView.isScrollEnabled = true
        
        // Handle Traffic layer customization, for iOS 9 and above
        if #available(iOS 9.0, *) {
            if let showsTraffic = self.customizationDelegate?.showTrafficForMapView?(map: self) {
                mapView.showsTraffic = showsTraffic
                
            } else {
                mapView.showsTraffic = false
            }
        }
        
        return mapView
    }
    
    func initHTView(mapView: UIView) {
        let bundleRoot = Bundle(for: HyperTrack.self)
        let bundle = Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
        let htView: HTView = bundle!.loadNibNamed("HTView", owner: self, options: nil)?.first as! HTView
        htView.initMapView(mapSubView: self.mapView, interactionViewDelegate: self)
        self.view = htView
    }
    
    func viewFor(_ mapType: HTMapProvider) -> MKMapView {
        var mapView: MKMapView
        
        switch mapType {
        case .appleMaps:
            mapView = MKMapView()
            (mapView as! MKMapView).isRotateEnabled = false
            (mapView as! MKMapView).isZoomEnabled = false
            (mapView as! MKMapView).camera.heading = 0.0
            break
            
        case .googleMaps:
            mapView = MKMapView() // TODO: Instantiate GoogleMaps view
            break
            
        case .openStreetMaps:
            mapView = MKMapView() // TODO: Instantiate OSM view
            break
        }
        
        return mapView
    }
    
    func providerFor(_ mapType: HTMapProvider) -> MapProviderProtocol {
        
        var provider: MapProviderProtocol
        
        switch mapType {
        case .appleMaps:
            provider = AppleMapsProvider(mapView:self.mapView as! MKMapView)
            break
            
        case .googleMaps:
            provider = AppleMapsProvider(mapView:self.mapView as! MKMapView) // TODO: Instantiate GoogleMaps Adapter
            break
            
        case .openStreetMaps:
            provider = AppleMapsProvider(mapView:self.mapView as! MKMapView) // TODO: Instantiate OSM Maps Adapter
            break
        }
        
        return provider
    }
    
    internal func didReceiveLocationUpdates(_ locations: [TimedCoordinates], action: HyperTrackAction?) {
        
        let newLocations = locations.filter{$0.timeStamp > self.lastPlottedTime}
        let coordinates = newLocations.map{$0.location}
        
        if let action = action {
            updateMapForAction(action, locations: coordinates)
        }
        
        if let lastPoint = newLocations.last {
            self.lastPlottedTime = lastPoint.timeStamp
        }
    }
    
    func updateMapForAction(_ action: HyperTrackAction, locations: [CLLocationCoordinate2D]) {
        
        print("\(Date()): Received \(locations.count) points for entityID: \(String(describing: action.id))")
        
        var coordinates = locations
        if locations.count > 50 { // MARK TODO- temporary check
            coordinates = Array(locations.suffix(from: locations.count - 50))
        }
        
        if self.lastPosition == nil {
            self.lastPosition = coordinates.first
        }
        
        updateDestinationForAction(action: action)
        updateHeroMarkerForAction(action: action, locations: coordinates)
        updateActionData(action: action)
        
        if let action = action as HyperTrackAction?, let actionStatus = action.status {
            if actionStatus != "completed" {
                let unitAnimationDuration = 5.0 / Double(coordinates.count)
                self.mapProvider?.animateMarker(locations: coordinates, currentIndex: 0, duration: unitAnimationDuration)
            } else {
                self.mapProvider?.clearMap()
                self.mapProvider?.updatePolyline(polyline: action.encodedPolyline!)
                // Stop polling inside Action Store
                ActionStore.sharedInstance.pollingTimer?.invalidate()
            }
            
            if let user = action.user as HyperTrackUser? {
                if let phone = user.phone as String? {
                    self.phoneNumber = phone
                }
            }
        }
        
        self.mapProvider?.updateViewFocus(isInfoViewCardExpanded: self.view.isCardExpanded)
    }
    
    func updateDestinationForAction(action: HyperTrackAction) {
        // Handle destinationMarker customization
        if let showDestination = self.customizationDelegate?.showExpectedPlaceMarker?(map: self, actionID: action.id!) {
            self.mapProvider?.updateDestinationMarker(showDestination: showDestination, destinationAnnotation: nil)
            return
        }
        
        // Get annotation for destinationMarker
        var destination = self.lastPosition
        if let degrees = action.expectedPlace?.location?.coordinates {
            destination = CLLocationCoordinate2DMake((degrees.last)!, (degrees.first)!)
            self.destination = destination
        }
        
        // Update map for updated annotation
        if let destination = self.destination {
            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.coordinate = destination
            self.mapProvider?.updateDestinationMarker(showDestination: true, destinationAnnotation: destinationAnnotation)
        }
    }
    
    func updateHeroMarkerForAction(action: HyperTrackAction, locations: [CLLocationCoordinate2D]) {
        let annotation = MKPointAnnotation()
        if let coordinate = locations.first as CLLocationCoordinate2D? {
            annotation.coordinate = coordinate
            self.mapProvider?.updateHeroMarker(heroAnnotation: annotation, actionID: action.id!)
        }
    }
    
    func updateActionData(action: HyperTrackAction) {
        if let action = action as HyperTrackAction! {
            // Main card
            var destinationAddress: String = ""
            var etaMinutes: Double = 0
            var distanceLeft: Double = 0
            var distanceCovered: Double = 0
            var status: String = ""
            var timeElapsedMinutes: Double = 0
            var isCompleted = false
            
            // Expanded card
            var userName: String = ""
            var lastUpdated: Date = Date()
            var speed: Int = 0
            var battery: Int = 95
            var photoUrl: URL?
            
            if let startedAt = action.startedAt {
                var timeElapsed: Double?
                
                if action.completedAt != nil {
                    timeElapsed = startedAt.timeIntervalSince(action.completedAt!)
                } else {
                    timeElapsed = startedAt.timeIntervalSinceNow
                }
                
                timeElapsedMinutes = -1 * Double(timeElapsed! / 60)
            }
            
            if let place = action.expectedPlace {
                destinationAddress = place.address!
            }
            
            if let actionDisplay = action.display {
                if let duration = actionDisplay.durationRemaining {
                    let timeRemaining = duration
                    etaMinutes = Double(timeRemaining / 60)
                }
                
                if let statusText = actionDisplay.statusText {
                    status = statusText
                }
                
                if let distance = actionDisplay.distanceRemaining {
                    // Convert distance (meters) to miles and round to one decimal
                    distanceLeft = round(Double(distance) * 0.000621371 * 10) / 10
                }
            }
            
            if let action = action as HyperTrackAction?, let actionStatus = action.status {
                if actionStatus == "completed" {
                    isCompleted = true
                }
            }
            
            if let distance = action.distance {
                // Convert distance (meters) to miles and round to one decimal
                distanceCovered = round(distance * 0.000621371 * 10) / 10
            }
            
            if let user = action.user as HyperTrackUser? {
                userName = user.name!
                if let photo = user.photo {
                    photoUrl = URL(string: photo)
                }
                
                if let batteryPercentage = user.lastBattery {
                    battery = batteryPercentage
                }
                
                if let heartbeat = user.lastHeartbeatAt {
                    lastUpdated = heartbeat
                }
                
                if let location = user.lastLocation {
                    if location.speed >= 0 {
                        speed = Int(location.speed * 2.23693629)
                    }
                }
            }
            
            if isCompleted {
                showCompleteActionView(action: action)
            }
            
            // Check if address view has been customized and update accordingly
            if let isAddressViewShown = self.customizationDelegate?.showAddressViewForActionID?(map: self, actionID: action.id!) {
                self.isAddressViewShown = isAddressViewShown
            }
            self.view.updateAddressView(isAddressViewShown: self.isAddressViewShown, destinationAddress: destinationAddress)
            
            // Check if info view has been customized and update accordingly
            if let isInfoViewShown = self.customizationDelegate?.showInfoViewForActionID?(map: self, actionID: action.id!) {
                self.isInfoViewShown = isInfoViewShown
            }
            self.view.updateInfoView(isInfoViewShown: self.isInfoViewShown, eta: etaMinutes, distanceLeft: distanceLeft, status: status, isCompleted: isCompleted, userName: userName, lastUpdated: lastUpdated, timeElapsed: timeElapsedMinutes, distanceCovered: distanceCovered, speed: speed, battery: battery, photoUrl: photoUrl)
            
            // Check if ReFocus Button has been customized and update accordingly
            if let isRefocusButtonShown = self.customizationDelegate?.showReFocusButton?(map: self) {
                self.isRefocusButtonShown = isRefocusButtonShown
            }
            self.view.updateReFocusButton(isRefocusButtonShown: self.isRefocusButtonShown)
            
            // Check if Back Button has been customized and update accordingly
            if let isBackButtonShown = self.customizationDelegate?.showBackButton?(map: self) {
                self.isBackButtonShown = isBackButtonShown
            }
            self.view.updateBackButton(isBackButtonShown: self.isBackButtonShown)
        }
    }
    
    func showCompleteActionView(action: HyperTrackAction) {
        var startAddress = ""
        var completeAddress = ""
        
        if let startPlace = action.startedPlace {
            if let address = startPlace.address {
                startAddress = address
            }
        }
        
        if let completePlace = action.completedPlace {
            if let address = completePlace.address {
                completeAddress = address
            }
        }
        
        self.view.completeActionView(startTime: action.assignedAt!, endTime: action.completedAt!, origin: startAddress, destination: completeAddress)
    }
}
