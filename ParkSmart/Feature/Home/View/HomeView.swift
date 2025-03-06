

import SwiftUI
import MapKit

struct HomeView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
    @StateObject var groupsViewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
    @StateObject var mapViewModel = MapViewModelImpl()
    @State private var searchText = ""
    
    @State private var showCarsSheet = true
    @State private var showMoreSheet = false
    @State private var showAccountView = false
    @State private var showGroupsView = false
    @State private var showEditCar = false
   
    @State private var selectedCar: Car?
    @State private var isVehicleDeleted: Bool = false
    @State private var dismissCarsView = true
    @State private var showNavigationView = false
    
    var body: some View {
        ZStack {
            MapView()
                .environmentObject(carsViewModel)
                .environmentObject(mapViewModel)
                .environmentObject(sessionService)
                .environmentObject(groupsViewModel)

            // Search bar overlay at the bottom
            VStack {
                Spacer()
                SearchBar(text: $searchText) {
                    showNavigationView = true
                }
                .padding()
                .background(.thinMaterial) // Modern blur effect
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)
                .padding(.horizontal, 16)
            }
           
    
            
        }
  
        .fullScreenCover(isPresented: $showNavigationView) {
            CombinedNavigationView(mapViewModel: mapViewModel)
        }

   
        .onChange(of: carsViewModel.selectedCar) { newCar in
            DispatchQueue.main.async {
                selectedCar = newCar
            }
        }
        .alert("Error", isPresented: $mapViewModel.hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = mapViewModel.state {
                Text(error.localizedDescription)
            } else if case .unauthorized(let reason) = mapViewModel.state {
                Text(reason)
            } else {
                Text("Something went wrong")
            }
        }
        
        .onAppear {
            if let userId = sessionService.userDetails?.userId {
                Task {
                    await carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }
        .onChange(of: sessionService.userDetails) { newUserDetails in
            if let userId = sessionService.userDetails?.userId {
                Task {
                    await carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }
        .onReceive(groupsViewModel.$carListReload) { change in
            if let userId = sessionService.userDetails?.userId {
                Task {
                    await carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }
        .alert("Error", isPresented: $carsViewModel.hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = carsViewModel.state {
                Text(error.localizedDescription)
            } else {
                Text("Something went wrong")
            }
        }
    }
    
    private func refreshCars() async {
        if let userId = sessionService.userDetails?.userId {
            await carsViewModel.fetchUserCars(userId: userId)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        
        HomeView()
            .environmentObject(SessionServiceImpl())
    }
}



struct SearchBar: View {
    @Binding var text: String
    var onAdd: () -> Void  // Closure for handling the plus button action
    @State private var showNavigationView = false
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            // Make the entire text field a button
            Button(action: {
                showNavigationView = true
            }) {
                HStack {
                    Text(text.isEmpty ? "Search locations..." : text)
                        .foregroundColor(text.isEmpty ? .gray : .primary)
                    Spacer()
                }
                .padding(8)
                .background(Color.clear)
            }

            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .fullScreenCover(isPresented: $showNavigationView) {
            CombinedNavigationView(mapViewModel: MapViewModelImpl())
        }
        
        
    }
}



struct SearchBar2: View {
    @Binding var text: String
    var onAdd: () -> Void  // Closure for handling the plus button action
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search locations...", text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


struct CombinedNavigationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var mapViewModel: MapViewModelImpl
    @StateObject private var locationManager = LocationManager()
    @State private var searchText: String = ""
    @State private var searchResults: [LocationResult] = []
    @State private var selectedLocation: LocationResult?
    @State private var showingNavigation = false
    @State private var currentRoute: MKRoute?
    @State private var isMapReady = false
    @State private var showingTurnByTurnNavigation = false  // New state variable
    
    struct LocationResult: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
    }
    
    init(mapViewModel: MapViewModelImpl = MapViewModelImpl()) {
        _mapViewModel = StateObject(wrappedValue: mapViewModel)
    }
    
    var body: some View {
        ZStack {
            // Map layer
            if isMapReady {
                LocationMapView(route: currentRoute,
                              destination: selectedLocation?.coordinate ??
                                         CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                    .edgesIgnoringSafeArea(.all)
                    .opacity(showingNavigation ? 1 : 0)
            }
            
            // UI Layer
            VStack(spacing: 0) {
                // Search header
                HStack {
                    Button(action: {
                        if showingNavigation {
                            showingNavigation = false
                            selectedLocation = nil
                            currentRoute = nil
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: showingNavigation ? "chevron.left" : "xmark")
                            .foregroundColor(.primary)
                            .padding()
                    }
                    
                    if !showingNavigation {
                        SearchBar2(text: $searchText) {}
                            .padding(.trailing)
                    } else if let location = selectedLocation {
                        Text(location.title)
                            .font(.headline)
                        Spacer()
                    }
                }
                .background(Color(.systemBackground))
                
                if !showingNavigation {
                    // Search results
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(searchResults) { result in
                                Button(action: {
                                    selectedLocation = result
                                    showingNavigation = true
                                    calculateRoute(to: result.coordinate)
                                }) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading) {
                                            Text(result.title)
                                                .foregroundColor(.primary)
                                                .font(.body)
                                            Text(result.subtitle)
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                }
                                Divider()
                            }
                        }
                    }
                } else {
                    Spacer()
                    
                    // Navigation controls
                    if let route = currentRoute {
                        VStack(spacing: 16) {
                            HStack {
                                Text("\(Int(route.expectedTravelTime / 60)) min")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("\(String(format: "%.1f", route.distance / 1609.34)) mi")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            
                            HStack(spacing: 16) {
                                Button(action: { /* Leave later functionality */ }) {
                                    Text("Leave later")
                                        .foregroundColor(.blue)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    showingTurnByTurnNavigation = true
                                }) {
                                    Text("Go now")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingTurnByTurnNavigation) {
            if let route = currentRoute {
                TurnByTurnNavigationView(route: route)
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                searchForLocations(query: newValue)
            } else {
                searchResults = []
            }
        }
      
        
        .onAppear {
            locationManager.requestLocationAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isMapReady = true
                searchForLocations(query: "university")
            }
        }

    
    }
    
    private func searchForLocations(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let userLocation = locationManager.location?.coordinate ??
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default to SF
        
        request.region = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                DispatchQueue.main.async {
                    searchResults = response.mapItems.map { item in
                        LocationResult(
                            title: item.name ?? "Unknown Place",
                            subtitle: item.placemark.title ?? "",
                            coordinate: item.placemark.coordinate
                        )
                    }
                }
            }
        }
    }

    
    private func calculateRoute(to destination: CLLocationCoordinate2D) {
            let request = MKDirections.Request()
            
            if let userLocation = locationManager.location?.coordinate {
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
            } else {
                let defaultLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: defaultLocation))
            }
            
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .automobile
            // Request multiple routes
            request.requestsAlternateRoutes = true
            
            MKDirections(request: request).calculate { response, error in
                DispatchQueue.main.async {
                    if let routes = response?.routes {
                        // Find the shortest route by distance
                        let shortestRoute = routes.min(by: { $0.distance < $1.distance })
                        self.currentRoute = shortestRoute
                    }
                }
            }
        }
}


// Location Manager to handle location services
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
    }
}

import SwiftUI
import MapKit

struct LocationMapView: UIViewRepresentable {
    var route: MKRoute?
    var destination: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove existing annotations and overlays
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)
        
        // Add destination annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = destination
        uiView.addAnnotation(annotation)
        
        // Add route if available
        if let route = route {
            uiView.addOverlay(route.polyline)
            
            // Create a region that encompasses both the route and current location
            if let userLocation = uiView.userLocation.location?.coordinate {
                let points = [userLocation, destination]
                let mapRect = points.reduce(MKMapRect.null) { rect, coordinate in
                    let point = MKMapPoint(coordinate)
                    let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
                    return rect.union(pointRect)
                }
                
                // Add some padding around the route
                let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
                uiView.setVisibleMapRect(mapRect, edgePadding: padding, animated: true)
            } else {
                // Fallback if user location is not available
                let region = MKCoordinateRegion(
                    center: destination,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                uiView.setRegion(region, animated: true)
            }
        } else {
            // If no route, just center on destination
            let region = MKCoordinateRegion(
                center: destination,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LocationMapView

        init(_ parent: LocationMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}



import SwiftUI
import MapKit

// MARK: - TurnByTurnNavigationView
struct TurnByTurnNavigationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var navigationManager = NavigationManager()
    @State private var mapView: MKMapView?
    @State private var showEndNavigationAlert = false
    @State private var showParkingAssistanceAlert = false
    @State private var showParkingSpotList = false
    
    // Store the initial route and create a state variable for the current route
    private let initialRoute: MKRoute
    @State private var currentRoute: MKRoute
    @State private var selectedParkingSpot: ParkingSpot?
    
    init(route: MKRoute) {
        self.initialRoute = route
        // Initialize currentRoute with the initial route
        _currentRoute = State(initialValue: route)
    }
    
    var body: some View {
        ZStack {
            // Pass the current route to NavigationMapView
            NavigationMapView(route: currentRoute,
                              userLocation: navigationManager.currentLocation,
                              followsUserLocation: true,
                              mapViewStore: $mapView,
                              parkingSpots: showParkingSpotList ? navigationManager.availableParkingSpots : [])
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                NavigationHeader(
                    distance: navigationManager.remainingDistance,
                    time: navigationManager.remainingTime,
                    onClose: { showEndNavigationAlert = true },
                    onResetView: resetMapView
                )
                
                Spacer()
                
                if showParkingSpotList {
                    ParkingSpotListView(
                        parkingSpots: navigationManager.availableParkingSpots,
                        isLoading: navigationManager.isLoadingParkingSpots,
                        onSelect: { spot in
                            selectedParkingSpot = spot
                            navigationManager.navigateToParkingSpot(spot)
                            showParkingSpotList = false
                        },
                        onCancel: {
                            showParkingSpotList = false
                        },
                        navigationManager: navigationManager
                    )
                    .transition(.move(edge: .bottom))
                } else {
                    InstructionPanel(
                        currentInstruction: navigationManager.currentInstruction,
                        nextInstruction: navigationManager.nextInstruction,
                        distanceToNextTurn: navigationManager.distanceToNextManeuver
                    )
                }
            }
        }
        .onAppear {
            navigationManager.startNavigation(for: initialRoute)
            // Register for the approaching destination notification
            navigationManager.onApproachingDestination = {
                showParkingAssistanceAlert = true
            }
        }
        .onChange(of: navigationManager.routeRecalculated) { recalculated in
            if recalculated, let newRoute = navigationManager.route {
                // Update the current route when recalculation happens
                self.currentRoute = newRoute
            }
        }
        .alert("End Navigation?", isPresented: $showEndNavigationAlert) {
            Button("End", role: .destructive) {
                navigationManager.stopNavigation()
                dismiss()
            }
            Button("Continue", role: .cancel) {}
        }
        .alert("You're almost at your destination", isPresented: $showParkingAssistanceAlert) {
            Button("Find parking", action: {
                navigationManager.findParkingSpots()
                showParkingSpotList = true
            })
            Button("Continue to destination", role: .cancel) {}
        } message: {
            Text("Would you like to find an available parking space nearby?")
        }
    }
    
    private func resetMapView() {
        guard let mapView = mapView else { return }
        let camera = MKMapCamera()
        camera.pitch = 60 // Reset to default tilted view
        camera.altitude = 200 // Reset to default navigation altitude
        if let location = navigationManager.currentLocation {
            camera.centerCoordinate = location.coordinate
            camera.heading = location.course
        }
        mapView.setCamera(camera, animated: true)
    }
}

// Model for Parking Spots
import CoreLocation

struct ParkingSpot: Identifiable {
    let id = UUID()  // Unique identifier
    let coordinate: CLLocationCoordinate2D
    let name: String
    let available: Bool
    let distance: Double
    let firebaseId: String?

    init(coordinate: CLLocationCoordinate2D, name: String, available: Bool, distance: Double, firebaseId: String?) {
        self.coordinate = coordinate
        self.name = name
        self.available = available
        self.distance = distance
        self.firebaseId = firebaseId
    }
}

extension ParkingSpot {
    var formattedDistance: String {
        String(format: "%.2f meters", distance)
    }
}


// Parking Spot List View
// Enhanced Parking Spot List View with loading state and reservation
struct ParkingSpotListView: View {
    let parkingSpots: [ParkingSpot]
    let isLoading: Bool
    let onSelect: (ParkingSpot) -> Void
    let onCancel: () -> Void
    @State private var reservingSpot: String? = nil
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack {
            HStack {
                Text("Available Parking")
                    .font(.headline)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                VStack {
                    ProgressView()
                        .padding()
                    Text("Searching for parking...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else if parkingSpots.filter({ $0.available }).isEmpty {
                VStack {
                    Image(systemName: "car.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .padding()
                    Text("No available parking spots found nearby")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else {
                List {
                    ForEach(parkingSpots.filter { $0.available }) { spot in
                        Button(action: {
                            reservingSpot = spot.id.uuidString
                            navigationManager.reserveParkingSpot(spot) { success in
                                if success {
                                    onSelect(spot)
                                }
                                reservingSpot = nil
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(spot.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Available")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                if reservingSpot == spot.id.uuidString {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Text(spot.formattedDistance)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(reservingSpot != nil)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .frame(height: 250)
            }
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
}

// Enhanced Navigation Map View to display parking spots
struct NavigationMapView: UIViewRepresentable {
    let route: MKRoute
    var userLocation: CLLocation?
    var followsUserLocation: Bool
    @Binding var mapViewStore: MKMapView?
    var parkingSpots: [ParkingSpot] = []

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = followsUserLocation ? .followWithHeading : .none

        // Configure camera for navigation
        let camera = MKMapCamera()
        camera.pitch = 60
        camera.altitude = 200
        mapView.camera = camera

        // Store the mapView reference
        context.coordinator.setMapView(mapView)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Clear existing overlays and annotations except user location
        mapView.removeOverlays(mapView.overlays)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)

        // Add route overlay
        mapView.addOverlay(route.polyline)
        
        // Add parking spot annotations
        for spot in parkingSpots {
            let annotation = ParkingSpotAnnotation(
                coordinate: spot.coordinate,
                title: spot.name,
                subtitle: spot.available ? "Available" : "Occupied",
                isAvailable: spot.available
            )
            mapView.addAnnotation(annotation)
        }

        if followsUserLocation, let location = userLocation {
            // Adjust camera to follow user
            let camera = mapView.camera
            camera.centerCoordinate = location.coordinate
            camera.heading = location.course
            mapView.setCamera(camera, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NavigationMapView

        init(_ parent: NavigationMapView) {
            self.parent = parent
            super.init()
        }

        func setMapView(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.mapViewStore = mapView
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            if let parkingAnnotation = annotation as? ParkingSpotAnnotation {
                let identifier = "parkingSpot"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Customize based on availability
                annotationView?.markerTintColor = parkingAnnotation.isAvailable ? .green : .red
                annotationView?.glyphImage = UIImage(systemName: "car.fill")
                return annotationView
            }
            
            // For destination and other annotations
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

// Custom annotation for parking spots
class ParkingSpotAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let isAvailable: Bool
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, isAvailable: Bool) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.isAvailable = isAvailable
        super.init()
    }
}

// Enhanced Navigation Manager with Parking functionality
import MapKit
import CoreLocation
import Combine
import FirebaseFirestore

import FirebaseAuth

// Enhanced Navigation Manager with Firebase Parking functionality
class NavigationManager: NSObject, ObservableObject {
    private var locationManager: CLLocationManager
    private var internalRoute: MKRoute?
    private var currentStepIndex: Int = 0
    private var navigationStartTime: Date?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private let destinationThreshold: Double = 200 // meters
    private var hasNotifiedApproaching = false
    public let db = Firestore.firestore()
    
    @Published var currentLocation: CLLocation?
    @Published var remainingDistance: Double = 0
    @Published var remainingTime: TimeInterval = 0
    @Published var currentInstruction: String = ""
    @Published var nextInstruction: String = ""
    @Published var distanceToNextManeuver: Double = 0
    @Published var routeRecalculated: Bool = false
    @Published var availableParkingSpots: [ParkingSpot] = []
    @Published var isLoadingParkingSpots: Bool = false
    
    // Callback for approaching destination
    var onApproachingDestination: (() -> Void)?
    
    // Public getter for route to avoid naming conflict
    var route: MKRoute? {
        return internalRoute
    }
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.distanceFilter = 10
    }
    
    func startNavigation(for route: MKRoute) {
        self.internalRoute = route
        navigationStartTime = Date()
        currentStepIndex = 0
        locationManager.startUpdatingLocation()
        hasNotifiedApproaching = false
        
        // Initialize navigation values immediately
        destinationCoordinate = route.steps.last?.polyline.coordinates.last
        remainingDistance = route.distance
        remainingTime = route.expectedTravelTime
        
        // Initialize instructions
        if let firstStep = route.steps.first {
            currentInstruction = firstStep.instructions
            nextInstruction = route.steps.count > 1 ? route.steps[1].instructions : "Arrive at destination"
            
            // Initialize distance to next maneuver
            if let userLocation = locationManager.location {
                distanceToNextManeuver = calculateDistance(
                    from: userLocation.coordinate,
                    to: firstStep.polyline.coordinates.last!
                )
            }
        }
    }
    
    func stopNavigation() {
        locationManager.stopUpdatingLocation()
        internalRoute = nil
        navigationStartTime = nil
        destinationCoordinate = nil
        hasNotifiedApproaching = false
    }
    
    // Fetch parking spots from Firebase
    func findParkingSpots() {
        guard let destination = destinationCoordinate else { return }
        
        // Clear previous spots and set loading state
        availableParkingSpots = []
        isLoadingParkingSpots = true
        
        // Search for parking spots within a radius of the destination
        let radius = 500.0 // meters
        
        // Convert the radius to degrees latitude/longitude for the query
        // This is a rough approximation that works for small distances
        let latDelta = radius / 111000 // approx meters per degree latitude
        let lngDelta = radius / (111000 * cos(destination.latitude * Double.pi / 180))
        
        let minLat = destination.latitude - latDelta
        let maxLat = destination.latitude + latDelta
        let minLng = destination.longitude - lngDelta
        let maxLng = destination.longitude + lngDelta
        
        // Query Firestore for parking spots within the bounding box
        db.collection("parkingSpots")
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting parking spots: \(error.localizedDescription)")
                    self.isLoadingParkingSpots = false
                    return
                }
                
                var spots: [ParkingSpot] = []
                
                for document in snapshot?.documents ?? [] {
                    do {
                        if let data = document.data() as? [String: Any],
                           let latitude = data["latitude"] as? Double,
                           let longitude = data["longitude"] as? Double,
                           let name = data["name"] as? String,
                           let available = data["available"] as? Bool {
                            
                            // Filter by longitude here (Firestore can only query on one range at a time)
                            if longitude >= minLng && longitude <= maxLng {
                                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let distance = self.calculateDistance(from: destination, to: coordinate)
                                
                                let spot = ParkingSpot(
                                    coordinate: coordinate,
                                    name: name,
                                    available: available,
                                    distance: distance,
                                    firebaseId: document.documentID
                                )
                                
                                spots.append(spot)
                            }
                        }
                    } catch {
                        print("Error decoding parking spot: \(error.localizedDescription)")
                    }
                }
                
                // Sort by distance
                spots.sort { $0.distance < $1.distance }
                
                DispatchQueue.main.async {
                    self.availableParkingSpots = spots
                    self.isLoadingParkingSpots = false
                }
            }
    }
    
    // Reserve the parking spot in Firebase
    func reserveParkingSpot(_ spot: ParkingSpot, completion: @escaping (Bool) -> Void) {
        guard let firebaseId = spot.firebaseId else {
            completion(false)
            return
        }
        
        // Update the spot availability in Firebase
        db.collection("parkingSpots").document(firebaseId).updateData([
            "available": false,
            "reservedAt": FieldValue.serverTimestamp(),
            "reservedBy": Auth.auth().currentUser?.uid ?? "anonymous"
        ]) { error in
            if let error = error {
                print("Error reserving parking spot: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    // Navigate to selected parking spot
    func navigateToParkingSpot(_ spot: ParkingSpot) {
        guard let userLocation = currentLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: spot.coordinate))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { [weak self] response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self?.internalRoute = route
                    self?.currentStepIndex = 0
                    self?.destinationCoordinate = spot.coordinate
                    self?.hasNotifiedApproaching = false
                    
                    if let firstStep = route.steps.first {
                        self?.currentInstruction = firstStep.instructions
                        self?.nextInstruction = route.steps.count > 1 ?
                            route.steps[1].instructions : "Arrive at parking spot"
                    }
                    
                    // Update remaining distance and time
                    self?.remainingDistance = route.distance
                    self?.remainingTime = route.expectedTravelTime
                    
                    // Notify UI that route has been recalculated
                    self?.routeRecalculated = true
                    
                    // Reset flag after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.routeRecalculated = false
                    }
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension NavigationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let route = internalRoute else { return }
        
        currentLocation = location
        
        // Update navigation progress
        updateNavigationProgress(at: location, for: route)
        
        // Check if approaching destination
        if !hasNotifiedApproaching,
           let destinationCoord = destinationCoordinate,
           calculateDistance(from: location.coordinate, to: destinationCoord) <= destinationThreshold {
            hasNotifiedApproaching = true
            DispatchQueue.main.async {
                self.onApproachingDestination?()
            }
        }
    }
    
    private func updateNavigationProgress(at location: CLLocation, for route: MKRoute) {
        let routeCoordinates = route.polyline.coordinates
        
        // Find closest point on route
        if let (closestPoint, distance) = findClosestPoint(to: location.coordinate, on: routeCoordinates) {
            // Check if off route (more than 50 meters from route)
            if distance > 50 {
                // Request route recalculation
                recalculateRoute(from: location)
                return
            }
            
            // Update remaining distance and time
            updateRemainingNavigationInfo(from: closestPoint)
            
            // Update current step if needed
            updateCurrentStep(at: location)
        }
    }
    
    private func findClosestPoint(to point: CLLocationCoordinate2D, on route: [CLLocationCoordinate2D]) -> (CLLocationCoordinate2D, Double)? {
        var closestPoint = route[0]
        var minDistance = Double.infinity
        
        for coordinate in route {
            let distance = calculateDistance(from: point, to: coordinate)
            if distance < minDistance {
                minDistance = distance
                closestPoint = coordinate
            }
        }
        
        return (closestPoint, minDistance)
    }
    
    func calculateDistance(from point1: CLLocationCoordinate2D, to point2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: point1.latitude, longitude: point1.longitude)
        let location2 = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
        return location1.distance(from: location2)
    }
    
    private func updateRemainingNavigationInfo(from currentPoint: CLLocationCoordinate2D) {
        guard let route = internalRoute else { return }
        
        // Calculate remaining distance
        remainingDistance = calculateRemainingDistance(from: currentPoint)
        
        // Update remaining time based on proportion of distance remaining
        let progressRatio = remainingDistance / route.distance
        remainingTime = route.expectedTravelTime * progressRatio
    }
    
    private func calculateRemainingDistance(from currentPoint: CLLocationCoordinate2D) -> Double {
        guard let route = internalRoute else { return 0 }
        
        var remainingDistance = 0.0
        let currentLocation = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
        
        // Start from current step
        for stepIndex in currentStepIndex..<route.steps.count {
            let step = route.steps[stepIndex]
            let stepCoordinates = step.polyline.coordinates
            
            if stepIndex == currentStepIndex {
                // For current step, calculate distance from current location to end of step
                if let (closestPointOnStep, _) = findClosestPoint(to: currentPoint, on: stepCoordinates) {
                    
                    var partialStepDistance = 0.0
                    var foundClosestPoint = false
                    
                    for i in 0..<(stepCoordinates.count - 1) {
                        let coord1 = stepCoordinates[i]
                        let coord2 = stepCoordinates[i + 1]
                        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
                        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
                        
                        if !foundClosestPoint {
                            let closestLoc = CLLocation(latitude: closestPointOnStep.latitude,
                                                        longitude: closestPointOnStep.longitude)
                            if loc1.distance(from: closestLoc) < 10 { // Within 10 meters
                                foundClosestPoint = true
                            }
                            continue
                        }
                        
                        partialStepDistance += loc1.distance(from: loc2)
                    }
                    remainingDistance += partialStepDistance
                }
            } else {
                // For future steps, add entire step distance
                for i in 0..<(stepCoordinates.count - 1) {
                    let coord1 = stepCoordinates[i]
                    let coord2 = stepCoordinates[i + 1]
                    let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
                    let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
                    remainingDistance += loc1.distance(from: loc2)
                }
            }
        }
        
        return remainingDistance
    }
    
    private func updateCurrentStep(at location: CLLocation) {
        guard let route = internalRoute else { return }
        
        let steps = route.steps
        if currentStepIndex < steps.count {
            let currentStep = steps[currentStepIndex]
            
            // Check if we've completed the current step
            if hasCompletedStep(currentStep, at: location) {
                currentStepIndex += 1
                
                // Update instructions
                if currentStepIndex < steps.count {
                    currentInstruction = steps[currentStepIndex].instructions
                    nextInstruction = currentStepIndex + 1 < steps.count ?
                        steps[currentStepIndex + 1].instructions : "Arrive at destination"
                }
            }
            
            // Update distance to next maneuver
            distanceToNextManeuver = calculateDistance(from: location.coordinate,
                                                       to: currentStep.polyline.coordinates.last!)
        }
    }
    
    private func hasCompletedStep(_ step: MKRoute.Step, at location: CLLocation) -> Bool {
        guard let stepEndPoint = step.polyline.coordinates.last else { return false }
        let distanceToStepEnd = calculateDistance(from: location.coordinate, to: stepEndPoint)
        return distanceToStepEnd < 20 // Consider step completed when within 20 meters
    }
    
    private func recalculateRoute(from location: CLLocation) {
        guard let destinationCoordinate = destinationCoordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.requestsAlternateRoutes = true // Request multiple routes
        
        MKDirections(request: request).calculate { [weak self] response, error in
            if let routes = response?.routes {
                // Find the shortest route by distance
                let shortestRoute = routes.min(by: { $0.distance < $1.distance })
                
                DispatchQueue.main.async {
                    if let newRoute = shortestRoute {
                        self?.internalRoute = newRoute
                        self?.currentStepIndex = 0
                        if let firstStep = newRoute.steps.first {
                            self?.currentInstruction = firstStep.instructions
                            self?.nextInstruction = newRoute.steps.count > 1 ?
                                newRoute.steps[1].instructions : "Arrive at destination"
                        }
                        
                        // Notify UI that route has been recalculated
                        self?.routeRecalculated = true
                        
                        // Reset flag after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self?.routeRecalculated = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Real-time Parking Spot Updates
    
    // Set up a real-time listener for parking spot availability changes
    func setupParkingSpotListener() {
        guard let destination = destinationCoordinate else { return }
        
        // Calculate the bounding box
        let radius = 500.0 // meters
        let latDelta = radius / 111000
        let lngDelta = radius / (111000 * cos(destination.latitude * Double.pi / 180))
        
        let minLat = destination.latitude - latDelta
        let maxLat = destination.latitude + latDelta
        
        // Listen for changes to available parking spots
        db.collection("parkingSpots")
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .whereField("available", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    if let error = error {
                        print("Error listening for parking updates: \(error.localizedDescription)")
                    }
                    return
                }
                
                // If we already have parking spots, update them
                if !self.availableParkingSpots.isEmpty {
                    self.findParkingSpots() // Refresh the list
                }
            }
    }
    
    // Release a parking spot (if the user cancels or leaves)
    func releaseParkingSpot(_ spot: ParkingSpot, completion: @escaping (Bool) -> Void) {
        guard let firebaseId = spot.firebaseId else {
            completion(false)
            return
        }
        
        // Check if the spot was reserved by the current user
        db.collection("parkingSpots").document(firebaseId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let reservedBy = data["reservedBy"] as? String,
                  reservedBy == Auth.auth().currentUser?.uid || reservedBy == "anonymous" else {
                completion(false)
                return
            }
            
            // Update the spot availability in Firebase
            self?.db.collection("parkingSpots").document(firebaseId).updateData([
                "available": true,
                "reservedAt": FieldValue.delete(),
                "reservedBy": FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("Error releasing parking spot: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
    
    // Search for parking spots with specific criteria
    func searchParkingWithFilter(maxDistance: Double? = nil,
                                 preferCovered: Bool = false,
                                 maxPricePerHour: Double? = nil) {
        guard let destination = destinationCoordinate else { return }
        
        // Clear previous spots and set loading state
        availableParkingSpots = []
        isLoadingParkingSpots = true
        
        // Search radius
        let radius = maxDistance ?? 500.0 // Use provided max distance or default to 500m
        
        // Convert the radius to degrees latitude/longitude for the query
        let latDelta = radius / 111000
        let lngDelta = radius / (111000 * cos(destination.latitude * Double.pi / 180))
        
        let minLat = destination.latitude - latDelta
        let maxLat = destination.latitude + latDelta
        let minLng = destination.longitude - lngDelta
        let maxLng = destination.longitude + lngDelta
        
        // Start with base query
        var query: Query = db.collection("parkingSpots")
            .whereField("latitude", isGreaterThanOrEqualTo: minLat)
            .whereField("latitude", isLessThanOrEqualTo: maxLat)
            .whereField("available", isEqualTo: true)
        
        // Add covered filter if requested
        if preferCovered {
            query = query.whereField("covered", isEqualTo: true)
        }
        
        // Add price filter if requested
        if let maxPrice = maxPricePerHour {
            query = query.whereField("pricePerHour", isLessThanOrEqualTo: maxPrice)
        }
        
        // Execute the query
        query.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error searching for parking spots: \(error.localizedDescription)")
                self.isLoadingParkingSpots = false
                return
            }
            
            var spots: [ParkingSpot] = []
            
            for document in snapshot?.documents ?? [] {
                do {
                    if let data = document.data() as? [String: Any],
                       let latitude = data["latitude"] as? Double,
                       let longitude = data["longitude"] as? Double,
                       let name = data["name"] as? String,
                       let available = data["available"] as? Bool {
                        
                        // Filter by longitude here (Firestore can only query on one range at a time)
                        if longitude >= minLng && longitude <= maxLng {
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            let distance = self.calculateDistance(from: destination, to: coordinate)
                            
                            // Apply distance filter here, in case maxDistance was provided
                            if maxDistance == nil || distance <= maxDistance! {
                                let spot = ParkingSpot(
                                    coordinate: coordinate,
                                    name: name,
                                    available: available,
                                    distance: distance,
                                    firebaseId: document.documentID
                                )
                                
                                spots.append(spot)
                            }
                        }
                    }
                } catch {
                    print("Error decoding parking spot: \(error.localizedDescription)")
                }
            }
            
            // Sort by distance
            spots.sort { $0.distance < $1.distance }
            
            DispatchQueue.main.async {
                self.availableParkingSpots = spots
                self.isLoadingParkingSpots = false
            }
        }
    }
}

// Extension to get coordinates from MKPolyline
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}



class DirectionalAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let heading: Double
    
    init(coordinate: CLLocationCoordinate2D, heading: Double) {
        self.coordinate = coordinate
        self.heading = heading
        super.init()
    }
}



struct NavigationHeader: View {
    let distance: Double
    let time: TimeInterval
    let onClose: () -> Void
    let onResetView: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack {
                Text(formatDistance(distance))
                    .font(.headline)
                Text(formatTime(time))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Reset view button
            Button(action: onResetView) {
                Image(systemName: "location.fill")
                    .foregroundColor(.primary)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
}

struct InstructionPanel: View {
    let currentInstruction: String
    let nextInstruction: String
    let distanceToNextTurn: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Current instruction
            HStack {
                Image(systemName: "arrow.turn.right.up")
                    .font(.title2)
                Text(currentInstruction)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatDistance(distanceToNextTurn))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Next instruction
            HStack {
                Image(systemName: "arrow.turn.right.up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Then " + nextInstruction.lowercased())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f ft", meters * 3.28084)
        } else {
            let miles = meters / 1609.34
            return String(format: "%.1f mi", miles)
        }
    }
}
