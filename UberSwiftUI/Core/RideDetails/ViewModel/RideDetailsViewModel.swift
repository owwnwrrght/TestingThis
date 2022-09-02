//
//  RideDetailsViewModel.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 8/31/22.
//

import Foundation
import MapKit
import Firebase
import SwiftUI

//enum TripState: Int {
//    case none
//    case locationSelected
//    case requested
//    case accepted
//    case inProgress
//    case completed
//}

class RideDetailsViewModel: ObservableObject {
        
    private let userLocation: CLLocation
    private let dropOffLocation: UberLocation
    private let nearbyDrivers: [User]
    private let selectedLocation: UberLocation
    
    var startLocationString: String
    var endLocationString: String
    
    @Published var pickupTime: String?
    @Published var dropOffTime: String?
    @Binding var mapState: MapViewState
    
    let distanceInMeters: Double
    
    init(userLocation: CLLocation, selectedLocation: UberLocation, nearbyDrivers: [User], mapState: Binding<MapViewState>) {
        self.startLocationString = "Current location"
        self.endLocationString = selectedLocation.title
        self.userLocation = userLocation
        self.dropOffLocation = selectedLocation
        self.nearbyDrivers = nearbyDrivers
        self.selectedLocation = selectedLocation
        self._mapState = mapState
        
        self.distanceInMeters =  userLocation.distance(from: CLLocation(latitude: selectedLocation.coordinate.latitude,
                                                                        longitude: selectedLocation.coordinate.longitude))
                
        
        calculateTripTime(forDistance: distanceInMeters)
    }
    
    func calculateTripTime(forDistance distance: Double) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropOffLocation.coordinate))
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            if let error = error {
                print("DEBUG: Failed to get directions with error \(error.localizedDescription)")
                return
            }
            
            guard let response = response, !response.routes.isEmpty else { return }
            guard let route = response.routes.first else { return }
            
            let expectedTravelTimeInSeconds = route.expectedTravelTime
            self.configurePickupAndDropOffTime(with: expectedTravelTimeInSeconds)
        }
    }
    
    func configurePickupAndDropOffTime(with expectedTravelTime: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        self.pickupTime = formatter.string(from: Date())
        self.dropOffTime = formatter.string(from: Date() + expectedTravelTime)
    }
    
    func requestRide() {
//        guard let closestDriver = nearbyDrivers.first else { return }
//        sendRideRequestToDriver(closestDriver)
        
        self.mapState = .tripRequested
    }
    
    func sendRideRequestToDriver(_ driver: User) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let driverId = driver.id else { return }
                
        let pickupGeoPoint = GeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let dropoffGeoPoint = GeoPoint(latitude: selectedLocation.coordinate.latitude, longitude: selectedLocation.coordinate.longitude)
        
        let data: [String: Any] = [
            "passengerId": currentUid,
            "pickupLocation": pickupGeoPoint,
            "dropoffLocation": dropoffGeoPoint,
            "tripState": MapViewState.tripRequested.rawValue
        ]
        
        COLLECTION_RIDES.document(driverId).setData(data) { _ in
            print("DEBUG: Did upload trip...")
//            self.tripState = .requested
        }
    }
}
