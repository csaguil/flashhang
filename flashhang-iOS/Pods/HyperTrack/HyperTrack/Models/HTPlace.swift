//
//  HTPlace.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 10/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

/**
 Instances of HyperTrackPlace represent the place entity: https://docs.hypertrack.com/api/entities/place.html
 */
@objc public class HyperTrackPlace:NSObject {

    /**
     Unique (uuid4) identifier for the place
     */
    public var id: String?
    
    /**
     Name of the place
     */
    public var name: String? = ""
    
    /**
     Location coordinates of the place
     */
    public var location: HTGeoJSONLocation?
    
    /**
     Address string of the place
     */
    public var address: String? = ""
    
    /**
     Landmark of the place
     */
    public var landmark: String? = ""
    
    /**
     Zip code of the place
     */
    public var zipCode: String? = ""
    
    /**
     City of the place
     */
    public var city: String? = ""
    
    /**
     State of the place
     */
    public var state: String? = ""
    
    /**
     Country of the place
     */
    public var country: String? = ""
    
    /**
     Method to get new place object
     */
    public override init() {
    }
    
    internal init(id: String?,
                name: String = "",
                location: HTGeoJSONLocation?,
                address: String = "",
                landmark: String = "",
                zipCode: String = "",
                city: String = "",
                state: String = "",
                country: String = "") {
        self.id = id
        self.name = name
        self.location = location
        self.address = address
        self.landmark = landmark
        self.zipCode = zipCode
        self.city = city
        self.state = state
        self.country = country
    }
    
    /**
     Method to set the name on a place object
     
     - Parameter name: Name of the place
     - Returns: The place object
     */
    public func setName(name: String = "") -> HyperTrackPlace {
        self.name = name
        return self
    }
    
    /**
     Method to set the location coordinates on a place object
     
     - Parameter latitude: Latitude of the place
     - Parameter longitude: Longitude of the place
     - Returns: The place object
     */
    public func setLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> HyperTrackPlace {
        let location = HTGeoJSONLocation(
            type: "point",
            coordinates: CLLocationCoordinate2DMake(latitude, longitude))
        self.location = location
        return self
    }
    
    /**
     Method to set the location coordinates on a place object
     
     - Parameter coordinates: Location coordinates of the place
     - Returns: The place object
     */
    public func setLocation(coordinates: CLLocationCoordinate2D) -> HyperTrackPlace {
        let location = HTGeoJSONLocation(type: "point", coordinates: coordinates)
        self.location = location
        return self
    }
    
    /**
     Method to set the address on a place object
     
     - Parameter address: Address of the place
     - Returns: The place object
     */
    public func setAddress(address: String = "") -> HyperTrackPlace {
        self.address = address
        return self
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "id": self.id as Any,
            "name": self.name as Any,
            "location": self.location?.toDict() as Any,
            "address": self.address as Any,
            "landmark": self.landmark as Any,
            "zip_code": self.zipCode as Any,
            "city": self.city as Any,
            "state": self.state as Any,
            "country": self.country as Any
            ] as [String:Any]
        return dict
    }
    
    internal func toJson() -> String? {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString
        } catch {
            debugPrint("Error serializing object to JSON: %@", error.localizedDescription)
            return nil
        }
    }
    
    internal static func fromDict(dict:[String:Any]?) -> HyperTrackPlace? {
        guard let dict = dict else {
            return nil
        }

        guard let id = dict["id"] as? String,
            let name = dict["name"] as? String?,
            let location = dict["location"] as? [String:Any]?,
            let address = dict["address"] as? String?,
            let landmark = dict["landmark"] as? String?,
            let zipCode = dict["zip_code"] as? String?,
            let city = dict["city"] as? String?,
            let state = dict["state"] as? String?,
            let country = dict["country"] as? String? else {
                return nil
        }
        
        let htLocation = HTGeoJSONLocation.fromDict(dict: location!)
        
        let place = HyperTrackPlace(
            id: id,
            name: name!,
            location: htLocation,
            address: address!,
            landmark: landmark!,
            zipCode: zipCode!,
            city: city!,
            state: state!,
            country: country!)
        
        return place
    }
    
    internal static func fromJson(text:String) -> HyperTrackPlace? {
        if let data = text.data(using: .utf8) {
            do {
                let userDict = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let dict = userDict as? [String : Any] else {
                    return nil
                }
                
                return self.fromDict(dict:dict)
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
