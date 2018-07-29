//
//  AppleMapsProvider.swift
//  HyperTrack
//
//  Created by Anil Giri on 28/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit


class HTImageAnnotation: MKPointAnnotation {
    var markerView: UIView
    
    init(markerView: UIView) {
        self.markerView = markerView
        super.init()
    }
}


class AppleMapsProvider: NSObject, MapProviderProtocol, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    let mapView: MKMapView
    var annotations: [String: MKAnnotation]
    
    var currentHeading: CLLocationDegrees = 0.0
    var lastPosition: CLLocationCoordinate2D?
    var heroMarker: MKPointAnnotation?
    var destinationMarker: MKPointAnnotation?
    
    var reFocusDisabledByUserInteraction: Bool = false
    
    var mapInteractionDelegate: HTViewInteractionInternalDelegate?
    
    required init(mapView: MKMapView) {
        self.mapView = mapView
        self.annotations = Dictionary()
        super.init()
        self.mapView.delegate = self
        
        // This enables UI settings on MKMapView
        self.mapView.showsPointsOfInterest = true
        
        // This sets up the tap gesture recognizer.
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapMap(gestureRecognizer:)))
        singleTap.delegate = self
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        self.mapView.addGestureRecognizer(singleTap)
        
        // This sets up the pan gesture recognizer.
        let panRec: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanMap(gestureRecognizer:)))
        panRec.delegate = self
        self.mapView.addGestureRecognizer(panRec)
    }
    
    func didTapMap(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.ended) {
            self.mapInteractionDelegate?.didTapMapView?()
            reFocusDisabledByUserInteraction = true
        }
    }
    
    func didPanMap(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.ended) {
            self.mapInteractionDelegate?.didPanMapView?()
            reFocusDisabledByUserInteraction = true
        }
    }
    
    func reFocusMap(isInfoViewCardExpanded: Bool) {
        self.reFocusDisabledByUserInteraction = false
        self.updateViewFocus(isInfoViewCardExpanded: isInfoViewCardExpanded)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func zoomTo(visibleRegion: MKCoordinateRegion, animated: Bool = false)  {
        self.mapView.setRegion(visibleRegion, animated: animated)
    }
    
    // MARK: MapView Delegate methods
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tileOverlay = overlay as? MKTileOverlay else {
            return MKOverlayRenderer(overlay: overlay)
        }
        return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //    let userID = self.annotations.key // associate the MKAnnotation with userID and figure out the view to return
        if (annotation as! MKPointAnnotation) == self.heroMarker {
            return self.mapMarkerFor(userID: "") // TODO: Figure out the association
        } else if annotation is HTImageAnnotation {
            let imageAnnotation = annotation as! HTImageAnnotation
            return self.mapMarkerForView(markerView: imageAnnotation.markerView)
        } else {
            return self.mapMarkerForDestination()
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }
        
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.lineWidth = 3.0
        renderer.strokeColor = htBlack
        
        return renderer
    }
    
    // MARK: Helper methods
    func mapMarkerFor(userID: String) -> MKAnnotationView {
        let bundle = Settings.getBundle()
        var marker = self.mapView.dequeueReusableAnnotationView(withIdentifier: "map.marker.hero")
        if marker == nil {
            marker = MKAnnotationView()
        }
        let markerView: MarkerView = bundle!.loadNibNamed("MarkerView", owner: self, options: nil)?.first as! MarkerView
        return mapMarkerForView(markerView: markerView)
    }
    
    func mapMarkerForDestination() -> MKAnnotationView {
        let bundle = Settings.getBundle()
        let markerView: DestinationMarkerView = bundle!.loadNibNamed("DestinationMarkerView", owner: self, options: nil)?.first as! DestinationMarkerView
        return mapMarkerForView(markerView: markerView)
    }
    
    func mapMarkerForView(markerView: UIView) -> MKAnnotationView {
        let marker = MKAnnotationView()
        let adjustedOrigin = CGPoint(x: -markerView.frame.size.width / 2, y: -markerView.frame.size.height / 2)
        markerView.frame = CGRect(origin: adjustedOrigin, size: markerView.frame.size)
        
        marker.addSubview(markerView)
        marker.bringSubview(toFront: markerView)
        return marker
    }
    
    func updateDestinationMarker(showDestination: Bool, destinationAnnotation: MKPointAnnotation?) {
        if (showDestination) {
            // Add updated destinationAnnotation to map
            self.mapView.addAnnotation(destinationAnnotation!)
        }
        
        // Remove previous destinationAnnotation to map
        if let destinationMarker = self.destinationMarker {
            self.mapView.removeAnnotation(destinationMarker)
        }
        
        // Update destination marker reference
        self.destinationMarker = destinationAnnotation
    }
    
    func updateHeroMarker(heroAnnotation: MKPointAnnotation, actionID: String) {
        if self.heroMarker == nil {
            self.mapView.addAnnotation(heroAnnotation)
            self.heroMarker = heroAnnotation
            self.annotations.updateValue(heroAnnotation, forKey: actionID)
            self.heroMarker = heroAnnotation
        }
    }
    
    func animateMarker(locations: [CLLocationCoordinate2D], currentIndex: Int, duration: TimeInterval) {
        
        if let annotation = self.heroMarker, let coordinates = locations as [CLLocationCoordinate2D]? {
            
            if (coordinates.count < 1) {
                return
            }
            
            let currentLocation = coordinates[currentIndex]
            
            UIView.animate(withDuration: duration, animations: {annotation.coordinate = currentLocation}, completion: { (finished) in
                if(currentIndex < coordinates.count - 1) {
                    
                    if let lastPosition = self.lastPosition {
                        self.currentHeading = self.headingFrom(lastPosition, next: currentLocation)
                    }
                    
                    self.lastPosition = currentLocation
                    
                    if let view = self.mapView.view(for: annotation) {
                        
                        let adjustedHeading = self.mapView.camera.heading + self.currentHeading
                        view.transform = CGAffineTransform(rotationAngle: CGFloat(adjustedHeading * Double.pi / 180.0))
                        
                        self.animateMarker(locations: coordinates, currentIndex: currentIndex + 1, duration: duration)
                    }
                }
            })
        }
    }
    
    func updatePolyline(polyline: String) {
        mapPolylineFor(encodedPolyline: polyline)
    }
    
    func updateViewFocus(isInfoViewCardExpanded: Bool) {
        if (self.reFocusDisabledByUserInteraction) {
            return
        }
        
        var annotationsForFocus = self.mapView.annotations
        var overlaysForFocus = self.mapView.overlays
        
        var mapEdgePadding = UIEdgeInsets(top: 120, left: 40, bottom: 140, right: 40)
        if (isInfoViewCardExpanded) {
            mapEdgePadding = UIEdgeInsets(top: 120, left: 40, bottom: 260, right: 40)
        }
        
        var zoomRect:MKMapRect = MKMapRectNull
        
        for index in 0..<annotationsForFocus.count {
            let annotation = annotationsForFocus[index]
            let aPoint:MKMapPoint = MKMapPointForCoordinate(annotation.coordinate)
            let rect:MKMapRect = MKMapRectMake(aPoint.x, aPoint.y, 0.1, 0.1)
            
            if MKMapRectIsNull(zoomRect) {
                zoomRect = rect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, rect)
            }
        }
        
        for index in 0..<overlaysForFocus.count {
            let overlay = overlaysForFocus[index]
            let rect = overlay.boundingMapRect
            
            if MKMapRectIsNull(zoomRect) {
                zoomRect = rect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, rect)
            }
        }
        
        mapView.setVisibleMapRect(zoomRect, edgePadding: mapEdgePadding, animated: true)
    }
    
    func headingFrom(_ previous: CLLocationCoordinate2D, next: CLLocationCoordinate2D) -> CLLocationDegrees {
        
        let deltaX = next.latitude - previous.latitude
        let deltaY = next.longitude - previous.longitude
        
        return radiansToDegrees(radians: atan2(deltaY, deltaX)).truncatingRemainder(dividingBy: 360)
    }
    
    func radiansToDegrees(radians: Double) -> Double {
        return radians * 180 / Double.pi
    }
    
    func mapPolylineFor(encodedPolyline: String) {
        let coordinates = decodePolyline(encodedPolyline)
        
        let polyline = MKPolyline(coordinates: coordinates!, count: coordinates!.count)
        self.mapView.add(polyline)
        let bundle = Settings.getBundle()
        
        // Add circle and square at the start and end of the polyline
        if let first = coordinates?.first {
            let markerView: StartMarkerView = bundle!.loadNibNamed("StartMarkerView", owner: self, options: nil)?.first as! StartMarkerView
            let startAnnotation = HTImageAnnotation(markerView: markerView)
            startAnnotation.coordinate = first
            self.mapView.addAnnotation(startAnnotation)
        }
        
        if let last = coordinates?.last {
            let markerView: DestinationMarkerView = bundle!.loadNibNamed("DestinationMarkerView", owner: self, options: nil)?.first as! DestinationMarkerView
            let startAnnotation = HTImageAnnotation(markerView: markerView)
            startAnnotation.coordinate = last
            self.mapView.addAnnotation(startAnnotation)
        }
    }
    
    func clearMap() {
        let allAnnotations = self.mapView.annotations
        let allOverlays = self.mapView.overlays
        self.mapView.removeAnnotations(allAnnotations)
        self.mapView.removeOverlays(allOverlays)
        self.heroMarker = nil
        self.destinationMarker = nil
        self.lastPosition = nil
        self.currentHeading = 0
        self.annotations.removeAll()
    }
}
