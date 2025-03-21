

import MapKit
import Combine
import FirebaseFirestore
import CoreLocation
import _MapKit_SwiftUI
import SwiftUICore

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.891054)
    static let defaultCLLocationDegrees = 0.005
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: defaultCLLocationDegrees, longitudeDelta: defaultCLLocationDegrees)
}

enum LocationAuthState {
    case successful
    case unauthorized(reason: String)
    case failed(error: Error)
    case na
}

enum LocationAuthMessages {
    static let turnOnLocation = "This app needs your location to find it on the map. Please enable location services in your device's settings."
    static let unauthorized = "Your location is restricted."
    static let denied = "You have denied this app location permission. Go into settings to change it."
    static let cantRetrieve = "We were unable to retrieve your location."
}

protocol MapViewModel {
    var mapView: MKMapView { get }
    var manager: CLLocationManager { get }
    var searchText: String { get }
    var fetchedPlaces: [CLPlacemark]? { get }
    var userLocation: CLLocation? { get }
    var pickedLocation: CLLocation? { get }
    var pickedPlaceMark: CLPlacemark? { get }
    var region: MKCoordinateRegion { get }
    var newLocationRegion: MKCoordinateRegion { get }
    var state: LocationAuthState { get }
    var hasError: Bool { get }
    var selectedCoordinate: CLLocationCoordinate2D? { get }
    var isCurrentLocationClicked: Bool { get }
    func getCurrentLocation()
    func getCurrentLocationForNewLocationMap()
    func fetchPlaces(value: String)
    func addDragabblePin(coordinate: CLLocationCoordinate2D)
    func updatePlacemark(location: CLLocation)
    init()
}

final class MapViewModelImpl: NSObject, ObservableObject, MapViewModel{
    @Published var parkingSpots: [ParkingSpot] = []

    
    // Add these properties to your MapViewModelImpl class
    @Published var mapStyle: MapStyle = .imagery
    @Published var is3DEnabled: Bool = false
    
    //MARK: Properties
    @Published var mapView: MKMapView = .init()
    @Published var manager: CLLocationManager = .init()
    
    //MARK: Search Bar Text
    @Published var searchText: String = ""
    @Published var fetchedPlaces: [CLPlacemark]?
    
    //MARK: User Location
    @Published var userLocation: CLLocation?
    private let db = Firestore.firestore()
    //MARK: Final Location
    @Published var pickedLocation: CLLocation?
    @Published var pickedPlaceMark: CLPlacemark?
    
    @Published var state: LocationAuthState = .na
    @Published var hasError: Bool = false
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    @Published var isCurrentLocationClicked = true
    @Published var newLocationRegion = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var cancellable: AnyCancellable?
    
    override init() {
        super.init()
        setupErrorSubscription()
        
        //MARK: Setting Delegates
        manager.delegate = self
        mapView.delegate = self
        
        //MARK: Requesting Location Access
        manager.requestWhenInUseAuthorization()
        
        //MARK: Search TextField Watching
        cancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { value in
                if value != "" {
                    self.fetchPlaces(value: value)
                } else {
                    self.fetchedPlaces = nil
                }
            })
    }
    
    /// Get the current location of a user and show it inside the main map of the app
    @MainActor
    func getCurrentLocation() {
        if let location = self.manager.location {
            // Center the camera focus in proportion with the bottom sheet
            let centeredLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude - Constants.defaultSubtractionForMapAnnotation, longitude: location.coordinate.longitude)
            let currentLocation = MKCoordinateRegion(center: centeredLocation,
                                                     span: MapDetails.defaultSpan)
            self.region = currentLocation
            self.isCurrentLocationClicked = true
        }
    }
    
    func fetchParkingSpots() {
        let radius: Double = 500.0 // meters

        guard let userLocation = CLLocationManager().location?.coordinate else {
            return
        }

        let latDelta = radius / 111000 // approx meters per degree latitude
        let lngDelta = radius / (111000 * cos(userLocation.latitude * .pi / 180))

        let minLat = userLocation.latitude - latDelta
        let maxLat = userLocation.latitude + latDelta
        let minLng = userLocation.longitude - lngDelta
        let maxLng = userLocation.longitude + lngDelta

        db.collection("parkingSpots")
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting parking spots: \(error.localizedDescription)")
                    return
                }

                var spots: [ParkingSpot] = []

                for document in snapshot?.documents ?? [] {
                    if let data = document.data() as? [String: Any],
                       let latitude = data["latitude"] as? Double,
                       let longitude = data["longitude"] as? Double,
                       let name = data["name"] as? String,
                       let available = data["available"] as? Bool {

                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                        // Calculate distance from the user's location
                        let location = CLLocation(latitude: latitude, longitude: longitude)
                        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                        let distance = location.distance(from: userLoc) // distance in meters

                        // Get Firebase document ID
                        let firebaseId = document.documentID

                        let spot = ParkingSpot(coordinate: coordinate, name: name, available: available, distance: distance, firebaseId: firebaseId)

                        spots.append(spot)
                    }
                }

                DispatchQueue.main.async {
                    self.parkingSpots = spots
                }
            }
    }
    
    func countSpotsInLots(parkingSpots: [ParkingSpot], lots: [ParkingLot]) -> [ParkingLot] {
        var updatedLots = lots
        
        for (index, lot) in lots.enumerated() {
            let spotsInLot = parkingSpots.filter { spot in
                // Check if the spot is within the polygon
                isSpotInPolygon(spot: spot.coordinate, polygonCoordinates: lot.coordinates)
            }
            
            let availableSpotsCount = spotsInLot.filter { $0.available }.count
            updatedLots[index].availableSpots = availableSpotsCount
            updatedLots[index].totalSpots = spotsInLot.count
            
            // Update color based on availability ratio
            if updatedLots[index].totalSpots > 0 {
                let ratio = Double(availableSpotsCount) / Double(updatedLots[index].totalSpots)
                
                updatedLots[index].color = determineColorForRatio(ratio: ratio)
            } else {
                updatedLots[index].color = .gray
            }
        }
        
        return updatedLots
    }

    // Helper function to determine color based on ratio
    func determineColorForRatio(ratio: Double) -> Color {
        switch ratio {
        case 0.75...1.0:
            return .green
        case 0.5..<0.75:
            return .yellow
        case 0.25..<0.5:
            return .orange
        default:
            return .red
        }
    }

    // Helper function to check if a spot is within a polygon
    // Helper function to check if a spot is within a polygon


    func isSpotInPolygon(spot: CLLocationCoordinate2D, polygonCoordinates: [CLLocationCoordinate2D]) -> Bool {
        // Create an MKPolygon with the given coordinates
        let polygon = MKPolygon(coordinates: polygonCoordinates, count: polygonCoordinates.count)
        
        // Convert the spot to MKMapPoint
        let spotPoint = MKMapPoint(spot)
        
        // Check if the polygon intersects with the spot point
        return polygon.boundingMapRect.contains(spotPoint)
    }



    
}

//MARK: - CLLocationManagerDelegate
extension MapViewModelImpl: CLLocationManagerDelegate {
    
    /// Handle a cahnge of Auth in a location manager
    /// - Parameter manager: The location manager
    @MainActor
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            self.state = .unauthorized(reason: LocationAuthMessages.unauthorized)
        case .denied:
            self.state = .unauthorized(reason: LocationAuthMessages.denied)
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = manager.location {
                // Center the camera focus in proportion with the bottom sheet
                let centeredLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude - Constants.defaultSubtractionForMapAnnotation, longitude: location.coordinate.longitude)
                self.region = MKCoordinateRegion(center: centeredLocation, span: MapDetails.defaultSpan)
                
            } else {
                // Center the camera focus in proportion with the bottom sheet
                self.region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
                
            }
        @unknown default:
            // Center the camera focus in proportion with the bottom sheet
            self.region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
            self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
            
        }
    }
    
}

//MARK: MKMapViewDelegate
extension MapViewModelImpl: MKMapViewDelegate {
    
    /// Enabling Dragging inside a MKAnnotationView and adding an annotaion for a new parking position of a car
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PARKINGPIN")
        marker.isDraggable = true
        marker.isSelected = true
        marker.canShowCallout = false
        marker.glyphImage = UIImage(systemName: "mappin")
        marker.glyphTintColor = .black
        
        return marker
    }
    
    /// Handle a drag of an annotation in the map
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let newLocation = view.annotation?.coordinate else {return}
        self.pickedLocation = .init(latitude: newLocation.latitude, longitude: newLocation.longitude)
        updatePlacemark(location: .init(latitude: newLocation.latitude, longitude: newLocation.longitude))
    }
    
    /// Get the current location on the map where the user choose a new location for a car
    @MainActor
    func getCurrentLocationForNewLocationMap() {
        if let location = self.manager.location {
            let currentLocation = MKCoordinateRegion(center: location.coordinate,
                                                     span: MapDetails.defaultSpan)
            self.newLocationRegion = currentLocation
        } else {
            self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
        }
    }
    
    /// Fetching locations ("Places") of a text using MKLocalSearch & Async/Await
    /// - Parameter value: Text of a generic place
    func fetchPlaces(value: String) {
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = value.lowercased()
                request.region = self.region
                
                let response = try await MKLocalSearch(request: request).start()
                // We can also use Mainactor to publish changes in Main Thread
                await MainActor.run(body: {
                    self.fetchedPlaces = response.mapItems.compactMap({ item -> CLPlacemark? in
                        return item.placemark
                    })
                })
            } catch {
                
            }
        }
    }
    
    /// Add a draggable pin to MapView
    /// - Parameter coordinate: The coordinate in which the pin would be
    func addDragabblePin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Drag to your parking spot"
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
    }
    
    /// Updates the view's current location address
    /// - Parameter location: The chosen location
    func updatePlacemark(location: CLLocation) {
        Task {
            do {
                guard let place = try await reverseLocationCoordinates(location: location) else {return}
                await MainActor.run(body: {
                    self.pickedPlaceMark = place
                })
            } catch {
                
            }
        }
    }
    
    /// Displaying address of  CLLocation data
    /// - Parameter location: The location of the chosen place
    /// - Returns: The address of the chosen place
    private func reverseLocationCoordinates(location: CLLocation) async throws -> CLPlacemark? {
        let place = try await CLGeocoder().reverseGeocodeLocation(location).first
        return place
    }
}

//MARK: - Error handling
private extension MapViewModelImpl {
    
    func setupErrorSubscription() {
        $state.map { state -> Bool in
            switch state {
            case .successful, .na:
                return false
            case .unauthorized:
                return true
            case .failed:
                return true
            }
        }
        .assign(to: &$hasError)
    }
    
}
