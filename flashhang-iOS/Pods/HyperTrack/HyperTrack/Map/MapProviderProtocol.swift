//
//  MapProviderProtocol.swift
//  HyperTrack
//
//  Created by Anil Giri on 27/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

protocol MapProviderProtocol {
    
    var mapInteractionDelegate: HTViewInteractionInternalDelegate? {get set}
    
    func zoomTo(visibleRegion: MKCoordinateRegion, animated: Bool)
    func updateDestinationMarker(showDestination: Bool, destinationAnnotation: MKPointAnnotation?)
    func updateHeroMarker(heroAnnotation: MKPointAnnotation, actionID: String)
    func animateMarker(locations: [CLLocationCoordinate2D], currentIndex: Int, duration: TimeInterval)
    func reFocusMap(isInfoViewCardExpanded: Bool)
    func updatePolyline(polyline: String)
    func updateViewFocus(isInfoViewCardExpanded: Bool)
    func clearMap()
}
