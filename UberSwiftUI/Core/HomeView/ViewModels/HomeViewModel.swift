//
//  HomeViewModel.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 11/12/21.
//

import Foundation
import CoreLocation
import GeoFireUtils
import Firebase
import SwiftUI

class HomeViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var drivers = [User]()
    @Published var trip: Trip?
    @Published var mapState = MapViewState.noInput
    @Published var pickupTime: String?
    @Published var dropOffTime: String?
    @Published var user: User?
    
    var didExecuteFetchDrivers = false
    var userLocation: CLLocationCoordinate2D?
    var selectedLocation: UberLocation?
    
    private let radius: Double = 50 * 1000
    private var driverQueue = [User]()
    private var tripService = TripService()
    private var ridePrice = 0.0
    private var listenersDictionary = [String: ListenerRegistration]()
    private var tripDistanceInMeters = 0.0
    private var selectedRideType: RideType = .uberX

    // MARK: - Lifecycle
    
    init() {
        fetchUser()
    }
    
    // MARK: - Helpers
            
    private func reset() {
        self.mapState = .noInput
        self.selectedLocation = nil
        self.trip = nil
    }
    
    func viewForState(user: User) -> some View {
        switch mapState {
        case .tripRequested:
            if user.accountType == .passenger {
                return AnyView(TripLoadingView())
            } else {
                if let trip = trip {
                    return AnyView(AcceptTripView(trip: trip))
                }
            }
        case .tripAccepted:
            return AnyView(EnRouteToPickupLocationView())
        case .driverArrived:
            return user.accountType == .passenger ? AnyView(DriverArrivalView()) : AnyView(PickupPassengerView())
        case .tripInProgress:
            return AnyView(TripInProgressView())
        case .arrivedAtDestination:
            return AnyView(TripArrivalView(user: user))
        case .polylineAdded:
            if trip != nil {
                return AnyView(EnRouteToPickupLocationView())
            } else {
                return AnyView(RideRequestView())
            }
        default:
            break
        }
        
        return AnyView(Text(""))
    }
    
    func getPlacemark(forLocation location: CLLocation, completion: @escaping (CLPlacemark?, Error?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let placemark = placemarks?.first else { return }
            completion(placemark, nil)
        })
    }
    
    func addressFromPlacemark(_ placemark: CLPlacemark) -> String {
        var result = ""
        
        if let thoroughfare = placemark.thoroughfare {
             result += thoroughfare
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            result += " \(subThoroughfare)"
        }
        
        if let subadministrativeArea = placemark.subAdministrativeArea {
            result += ", \(subadministrativeArea)"
        }
        
        return result
    }
    
    func createPickupAndDropoffRegionsForTrip() {
        guard let trip = trip else { return }
        LocationManager.shared.createPickupRegionForTrip(trip)
        LocationManager.shared.createDropoffRegionForTrip(trip)
    }
    
    func getDestinationRoute(from userLocation: CLLocationCoordinate2D,
                             to destinationCoordinate: CLLocationCoordinate2D,
                             completion: @escaping(MKRoute) -> Void) {
        let userPlacemark = MKPlacemark(coordinate: userLocation)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: userPlacemark)
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            if let error = error {
                print("DEBUG: Failed to generate polyline with error \(error.localizedDescription)")
                return
            }
            
            guard let route = response?.routes.first else { return }
            self.configurePickupAndDropOffTime(with: route.expectedTravelTime)
            completion(route)
        }
    }
    
    func configurePickupAndDropOffTime(with expectedTravelTime: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        pickupTime = formatter.string(from: Date())
        dropOffTime = formatter.string(from: Date() + expectedTravelTime)
    }
    
    func ridePriceForType(_ type: RideType) -> Double {
        guard let selectedLocation = selectedLocation, let userCoordinates = userLocation else { return 0.0 }
        let userLocation = CLLocation(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)
        self.tripDistanceInMeters = userLocation.distance(from: CLLocation(latitude: selectedLocation.coordinate.latitude,
                                                                           longitude: selectedLocation.coordinate.longitude))
        return type.price(for: tripDistanceInMeters)
    }
}

// MARK: - Shared API

extension HomeViewModel {
    private func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        UserService.fetchUser(withUid: uid) { user in
            self.user = user
            self.tripService.user = user
            
            switch user.accountType {
            case .driver:
                self.addTripObserverForDriver()
            case .passenger:
                self.addTripObserverForPassenger()
            }
        }
    }
    
    private func updateTripState(_ trip: Trip, state: TripState, completion: ((Error?) -> Void)?) {
        COLLECTION_RIDES.document(trip.tripId).updateData(["tripState": state.rawValue], completion: completion)
    }
    
    private func deleteTrip() {
        guard let trip = trip else { return }
        
        COLLECTION_RIDES.document(trip.tripId).delete { _ in
            self.reset()
        }
    }
}

// MARK: - Driver API

extension HomeViewModel {
    func addTripObserverForDriver() {
        tripService.addTripObserverForDriver { snapshot, error in
            guard let change = snapshot?.documentChanges.first else { return }
            guard let trip = try? change.document.data(as: Trip.self) else { return }
            
            self.trip = trip
            self.tripService.trip = trip
            
            switch change.type {
            case .added, .modified:
                if trip.tripState == .requested {
                    self.mapState = .tripRequested
                } else if trip.tripState == .cancelled {
                    self.mapState = .tripCancelled
                    self.deleteTrip()
                } else if trip.tripState == .complete {
                    self.saveCompletedTrip(trip)
                }
                
            case .removed:
                self.mapState = .noInput
            }
        }
    }
    
    func acceptTrip() {
        guard let trip = trip else { return }
        self.selectedLocation = UberLocation(title: trip.dropoffLocationName, coordinate: trip.dropoffLocationCoordinates)
        
        tripService.acceptTrip { _ in
            self.createPickupAndDropoffRegionsForTrip()
            self.mapState = .tripAccepted
        }
    }
    
    func rejectTrip() {
        tripService.rejectTrip { _ in
            self.mapState = .noInput
        }
    }
    
    func updateTripStateToArrived() {
        tripService.didArriveAtPickupLocation { _ in
            self.mapState = .driverArrived
        }
    }
    
    func updateTripStateToDropoff() {
        tripService.didArriveAtPickupLocation { _ in
            self.mapState = .arrivedAtDestination
        }
    }
    
    func pickupPassenger() {
        tripService.pickupPassenger { _ in
            self.mapState = .tripInProgress
        }
    }
    
    func dropOffPassenger() {
        tripService.dropoffPassenger { _ in
            self.mapState = .tripCompleted
        }
    }
    
    func updateDriverActiveState(_ isActive: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        COLLECTION_USERS.document(uid).updateData(["isActive": isActive]) { _ in
            self.user?.isActive = isActive
        }
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let geoPoint = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        COLLECTION_USERS.document(uid).updateData(["coordinates": geoPoint])
    }
}

// MARK: - Passenger API

extension HomeViewModel {
   private func addTripObserverForPassenger() {
        guard let user = user, user.accountType == .passenger, let uid = user.id else { return }
        
        COLLECTION_RIDES.whereField("passengerUid", isEqualTo: uid).addSnapshotListener { snapshot, error in
            guard let change = snapshot?.documentChanges.first, change.type == .added || change.type == .modified else { return }
            switch change.type {
            case .added, .modified:
                guard let trip = try? change.document.data(as: Trip.self) else { return }
                self.trip = trip
                self.tripService.trip = trip
                
                if self.selectedLocation == nil {
                    self.selectedLocation = UberLocation(title: trip.dropoffLocationName, coordinate: trip.dropoffLocationCoordinates)
                }
                
                switch trip.tripState {
                case .rejectedByDriver:
                    self.requestRide(self.selectedRideType)
                case .accepted:
                    self.mapState = .tripAccepted
                case .driverArrived:
                    self.mapState = .driverArrived
                case .inProgress:
                    self.mapState = .tripInProgress
                case .arrivedAtDestination:
                    self.mapState = .arrivedAtDestination
                case .complete:
                    self.mapState = .tripCompleted
                    self.saveCompletedTrip(trip)
                case .cancelled:
                    self.mapState = .noInput
                default:
                    break
                }
            case .removed:
                print("DEBUG: Trip cancelled by driver")
                //TODO: Show notification to passenger that trip was cancelled
                self.mapState = .noInput
            }
        }
    }
    
    func requestRide(_ rideType: RideType) {
        guard let userLocation = userLocation else { return }
        self.ridePrice = rideType.price(for: self.tripDistanceInMeters)
        
        if driverQueue.isEmpty {
            guard let trip = trip else { return }
            updateTripState(trip, state: .rejectedByAllDrivers) { _ in
                self.deleteTrip()
                self.fetchNearbyDrivers(withCoordinates: userLocation)
            }
        } else {
            let driver = driverQueue.removeFirst()
            sendRideRequestToDriver(driver)
        }
    }
    
    func cancelTrip() {
        guard let trip = trip else { return }
        
        updateTripState(trip, state: .cancelled) { _ in
            self.reset()
        }
    }
    
    private func sendRideRequestToDriver(_ driver: User) {
        guard let user = user, let currentUid = user.id else { return }
        guard let driverUid = driver.id, driver.isActive else { return }
        guard let userLocation = userLocation, let selectedLocation = selectedLocation else { return }
        
        if let trip = trip {
            let updatedData: [String: Any] = [
                "tripState": TripState.requested.rawValue,
                "driverUid": driverUid
            ]
            COLLECTION_RIDES.document(trip.tripId).updateData(updatedData) { _ in
                print("DEBUG: Updated trip data..")
            }
        } else {
            let pickupGeoPoint = GeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let dropoffGeoPoint = GeoPoint(latitude: selectedLocation.coordinate.latitude, longitude: selectedLocation.coordinate.longitude)
            let driverGeoPoint = GeoPoint(latitude: driver.coordinates.latitude, longitude: driver.coordinates.longitude)
            
            getPlacemark(forLocation: CLLocation(latitude: pickupGeoPoint.latitude, longitude: pickupGeoPoint.longitude)) { placemark, error in
                guard let placemark = placemark else { return }

                let trip = Trip(driverUid: driverUid,
                                passengerUid: currentUid,
                                pickupLocation: pickupGeoPoint,
                                dropoffLocation: dropoffGeoPoint,
                                driverLocation: driverGeoPoint,
                                dropoffLocationName: selectedLocation.title,
                                pickupLocationName: placemark.name ?? "Current location",
                                pickupLocationAddress: self.addressFromPlacemark(placemark),
                                tripCost: self.ridePrice,
                                tripState: .requested,
                                driverName: driver.fullname,
                                passengerName: user.fullname,
                                driverImageUrl: driver.profileImageUrl ?? "",
                                passengerImageUrl: user.profileImageUrl)
                
                guard let encodedTrip = try? Firestore.Encoder().encode(trip) else { return }
                
                COLLECTION_RIDES.document().setData(encodedTrip) { _ in
                    self.mapState = .tripRequested
                }
            }
        }
    }
    
    //TODO: Extract to PassengerService
    func fetchNearbyDrivers(withCoordinates coordinates: CLLocationCoordinate2D) {
        let queryBounds = GFUtils.queryBounds(forLocation: coordinates, withRadius: radius)
        didExecuteFetchDrivers = true
        
        let queries = queryBounds.map { bound -> Query in
            return COLLECTION_USERS
                .order(by: "geohash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
        }
        
        for query in queries {
            query.getDocuments(completion: getDocumentsCompletion)
        }
    }
    
    private func getDocumentsCompletion(snapshot: QuerySnapshot?, error: Error?) -> () {
        guard let documents = snapshot?.documents else { return }
        guard let userLocation = userLocation else { return }
        var drivers = [User]()
        
        documents.forEach { doc in
            guard let driver = try? doc.data(as: User.self), driver.accountType == .driver else { return }
            let coordinates = CLLocation(latitude: driver.coordinates.latitude, longitude: driver.coordinates.longitude)
            let centerPoint = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            
            let distance = GFUtils.distance(from: centerPoint, to: coordinates)
            
            if distance <= radius {
                drivers.append(driver)
            }
        }
        
        self.drivers.append(contentsOf: drivers)
        self.driverQueue = self.drivers
        self.addListenerToDrivers()
    }
    
    func addListenerToDrivers() {
        for i in 0 ..< drivers.count {
            let driver = drivers[i]
            
            let driverListener = COLLECTION_USERS.document(driver.id ?? "").addSnapshotListener { snapshot, error in
                guard let driver = try? snapshot?.data(as: User.self) else { return }
                self.drivers[i].isActive = driver.isActive
                self.drivers[i].coordinates = driver.coordinates
            }
            
            self.listenersDictionary[driver.id ?? ""] = driverListener
        }
    }
    
    func removeListenersFromDrivers() {
        guard let trip = trip else { return }
        
        listenersDictionary.forEach { uid, listener in
            if uid != trip.driverUid {
                listener.remove()
            }
        }
    }
    
    func saveCompletedTrip(_ trip: Trip) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let encodedTrip = try? Firestore.Encoder().encode(trip) else { return }
        
        COLLECTION_USERS
            .document(uid)
            .collection("user-trips")
            .document(trip.tripId)
            .setData(encodedTrip) { _ in
                self.mapState = .noInput
            }
    }
}
