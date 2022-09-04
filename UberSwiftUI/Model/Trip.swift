//
//  Trip.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 9/2/22.
//

import FirebaseFirestoreSwift
import Firebase
import CoreLocation

struct Trip: Codable, Identifiable {
    @DocumentID var id: String?
    let driverUid: String
    let passengerUid: String
    let pickupLocation: GeoPoint
    let dropoffLocation: GeoPoint
    let dropoffLocationName: String
    let pickupLocationName: String
    let tripCost: Double
    let tripState: TripState
    
    var tripId: String { return id ?? "" }
    
    var dropoffLocationCoordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: dropoffLocation.latitude, longitude: dropoffLocation.longitude)
    }
    
    var pickupLocationCoordiantes: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: pickupLocation.latitude, longitude: pickupLocation.longitude)
    }
    
    var dropoffUberLocation: UberLocation {
        return UberLocation(title: dropoffLocationName, coordinate: dropoffLocationCoordinates)
    }
}

/*
    Need a link between trip state and map state
*/

enum TripState: Int, Codable {
    case driversUnavailable
    case rejectedByDriver
    case rejectedByAllDrivers
    case requested // value has to equal 3 to correspond to mapView tripRequested state
    case accepted
    case inProgress
    case complete
    case cancelled
}