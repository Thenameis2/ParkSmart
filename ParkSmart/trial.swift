import SwiftUI
import MapKit
import Combine


// MARK: - Models
struct Route: Identifiable {
    let id = UUID()
    let name: String
    let expectedTravelTime: TimeInterval
    let distance: Measurement<UnitLength>
    let transportType: MKDirectionsTransportType
    let polyline: MKPolyline
    let steps: [MKRoute.Step]
}

enum NavigationState {
    case idle
    case searching
    case routeSelected
    case navigating
}

// MARK: - View Models
class UserLocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3323, longitude: -122.0312),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension UserLocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        let coordinate = location.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        self.region = MKCoordinateRegion(center: coordinate, span: span)
    }
}

class NavigationViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedDestination: MKMapItem?
    @Published var routes: [Route] = []
    @Published var selectedRoute: Route?
    @Published var navigationState: NavigationState = .idle
    @Published var currentNavigationStep: MKRoute.Step?
    @Published var remainingSteps: [MKRoute.Step] = []
    @Published var isOffRoute: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let locationService: UserLocationService
    
    init(locationService: UserLocationService) {
        self.locationService = locationService
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard !text.isEmpty else {
                    self?.searchResults = []
                    return
                }
                self?.searchPlaces(query: text)
            }
            .store(in: &cancellables)
    }
    
    func searchPlaces(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = locationService.region
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let response = response, error == nil else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.searchResults = response.mapItems
                self?.navigationState = .searching
            }
        }
    }
    
    func selectDestination(_ destination: MKMapItem) {
        self.selectedDestination = destination
        self.findRoutes(to: destination)
    }
    
    func findRoutes(to destination: MKMapItem) {
        guard let userLocation = locationService.location else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self, let response = response, error == nil else {
                print("Directions error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.routes = response.routes.map { route in
                    return Route(
                        name: self.getRouteName(for: route),
                        expectedTravelTime: route.expectedTravelTime,
                        distance: Measurement(value: route.distance, unit: UnitLength.meters), // Convert here
                        transportType: .automobile,
                        polyline: route.polyline,
                        steps: route.steps
                    )
                }.sorted { $0.expectedTravelTime < $1.expectedTravelTime }

                
                if let fastestRoute = self.routes.first {
                    self.selectedRoute = fastestRoute
                }
                
                self.navigationState = .routeSelected
            }
        }
    }
    
    private func getRouteName(for route: MKRoute) -> String {
        if route.name.isEmpty {
            let minutes = Int(route.expectedTravelTime / 60)
            return "Route \(minutes) min"
        }
        return route.name
    }
    
    func startNavigation() {
        guard let selectedRoute = selectedRoute else { return }
        self.remainingSteps = selectedRoute.steps
        self.updateCurrentStep()
        self.navigationState = .navigating
        
        // Start monitoring for off-route conditions
        startRouteMonitoring()
    }
    
    private func updateCurrentStep() {
        guard !remainingSteps.isEmpty else {
            // Navigation complete
            self.navigationState = .idle
            self.currentNavigationStep = nil
            return
        }
        
        self.currentNavigationStep = remainingSteps.removeFirst()
    }
    
    func advanceToNextStep() {
        updateCurrentStep()
    }
    
    private func startRouteMonitoring() {
        // In a real app, you would continuously check if the user has deviated from the route
        // This is a simplified version for demonstration
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      let userLocation = self.locationService.location,
                      let selectedRoute = self.selectedRoute else { return }
                
                // Check if user is on route (simplified)
                let isOnRoute = self.isUserOnRoute(userLocation: userLocation, route: selectedRoute)
                if !isOnRoute && !self.isOffRoute {
                    self.isOffRoute = true
                    self.recalculateRoute()
                } else if isOnRoute && self.isOffRoute {
                    self.isOffRoute = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func isUserOnRoute(userLocation: CLLocation, route: Route) -> Bool {
        // Simplified check - in a real app you would use more sophisticated methods
        // like checking distance to the route's polyline
        return true // Placeholder
    }
    
    func recalculateRoute() {
        guard let destination = selectedDestination else { return }
        findRoutes(to: destination)
    }
    
    func cancelNavigation() {
        self.navigationState = .idle
        self.currentNavigationStep = nil
        self.remainingSteps = []
        self.selectedRoute = nil
        self.selectedDestination = nil
        self.isOffRoute = false
        
        // Cancel any route monitoring
        cancellables.removeAll()
    }
    
    func selectRoute(_ route: Route) {
        self.selectedRoute = route
    }
}

// MARK: - Views
struct MainView: View {
    @StateObject private var locationService = UserLocationService()
    @StateObject private var viewModel: NavigationViewModel
    
    init() {
        let locationService = UserLocationService()
        self._locationService = StateObject(wrappedValue: locationService)
        self._viewModel = StateObject(wrappedValue: NavigationViewModel(locationService: locationService))
    }
    
    var body: some View {
        ZStack {
            NavigationMapView2(locationService: locationService, viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                searchBar
                
                Spacer()
                
                bottomPanel
            }
            .padding()
        }
    }
    
    private var searchBar: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for a destination", text: $viewModel.searchText)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            
            if !viewModel.searchResults.isEmpty && viewModel.navigationState == .searching {
                SearchResultsView(viewModel: viewModel)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 2)
            }
        }
    }
    
    private var bottomPanel: some View {
        Group {
            switch viewModel.navigationState {
            case .idle:
                EmptyView()
                
            case .searching:
                EmptyView()
                
            case .routeSelected:
                RouteSelectionView(viewModel: viewModel)
                
            case .navigating:
                NavigationView(viewModel: viewModel)
            }
        }
    }
}

struct NavigationMapView2: UIViewRepresentable {
    @ObservedObject var locationService: UserLocationService
    @ObservedObject var viewModel: NavigationViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Set initial tracking mode but don't force it to stay this way
        mapView.userTrackingMode = .follow
        
        // Set the initial region once
        mapView.setRegion(locationService.region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Don't automatically update the region on each view update
        // Only update specific items that need changing
        
        // Clear previous overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { $0 !== mapView.userLocation })
        
        // Add destination pin if set
        if let destination = viewModel.selectedDestination {
            let annotation = MKPointAnnotation()
            annotation.coordinate = destination.placemark.coordinate
            annotation.title = destination.name
            mapView.addAnnotation(annotation)
        }
        
        // Add route overlay if available
        if let selectedRoute = viewModel.selectedRoute {
            mapView.addOverlay(selectedRoute.polyline)
            
            // Only zoom to show the entire route when a new route is selected
            if context.coordinator.previousRouteID != selectedRoute.id,
               let destination = viewModel.selectedDestination {
                context.coordinator.previousRouteID = selectedRoute.id
                
                let userLocation = locationService.location?.coordinate ?? mapView.userLocation.coordinate
                let bounds = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (userLocation.latitude + destination.placemark.coordinate.latitude) / 2,
                        longitude: (userLocation.longitude + destination.placemark.coordinate.longitude) / 2
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: abs(userLocation.latitude - destination.placemark.coordinate.latitude) * 2.5,
                        longitudeDelta: abs(userLocation.longitude - destination.placemark.coordinate.longitude) * 2.5
                    )
                )
                mapView.setRegion(bounds, animated: true)
            }
        }
        
        // Only force tracking mode in navigation state
        if viewModel.navigationState == .navigating {
            // Follow with heading during active navigation
            mapView.userTrackingMode = .followWithHeading
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NavigationMapView2
        var previousRouteID: UUID?
        var userPannedMap: Bool = false
        
        init(_ parent: NavigationMapView2) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Detect when user manually interacts with the map
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Check if this region change is from user interaction
            if let view = mapView.subviews.first,
               let gestureRecognizers = view.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    if recognizer.state == .began || recognizer.state == .changed {
                        userPannedMap = true
                        break
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Reset after region changes
            userPannedMap = false
        }
    }
}

struct SearchResultsView: View {
    @ObservedObject var viewModel: NavigationViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.searchResults, id: \.self) { item in
                    Button(action: {
                        viewModel.selectDestination(item)
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown Location")
                                .font(.headline)
                            if let address = item.placemark.thoroughfare {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                }
            }
            .padding()
        }
        .frame(height: min(CGFloat(viewModel.searchResults.count) * 60 + 20, 300))
    }
}

struct RouteSelectionView: View {
    @ObservedObject var viewModel: NavigationViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if let destination = viewModel.selectedDestination {
                Text(destination.name ?? "Selected Destination")
                    .font(.headline)
                    .padding(.bottom, 5)
            }
            
            Text("Route Options:")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.routes) { route in
                        RouteOptionCard(
                            route: route,
                            isSelected: viewModel.selectedRoute?.id == route.id,
                            onSelect: {
                                viewModel.selectRoute(route)
                            }
                        )
                    }
                }
            }
            .frame(height: 120)
            
            if let selectedRoute = viewModel.selectedRoute {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Trip Summary:")
                        .font(.headline)
                    
                    HStack {
                        Label(
                            formatDuration(selectedRoute.expectedTravelTime),
                            systemImage: "clock"
                        )
                        
                        Spacer()
                        
                        Label(
                            formatDistance(selectedRoute.distance),
                            systemImage: "map"
                        )
                    }
                    .padding(.vertical, 5)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: {
                    viewModel.startNavigation()
                }) {
                    Text("Start Navigation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hr \(remainingMinutes) min"
        }
    }
    
    private func formatDistance(_ distance: Measurement<UnitLength>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        return formatter.string(from: distance)
    }
}

struct RouteOptionCard: View {
    let route: Route
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 5) {
                Text(route.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "clock")
                    Text("\(Int(route.expectedTravelTime / 60)) min")
                }
                .font(.subheadline)
                
                HStack {
                    Image(systemName: "map")
                    Text(formatDistance(route.distance))
                }
                .font(.subheadline)
            }
            .padding()
            .frame(width: 150, height: 100)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDistance(_ distance: Measurement<UnitLength>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        return formatter.string(from: distance)
    }
}

struct NavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if let step = viewModel.currentNavigationStep {
                HStack {
                    VStack(alignment: .leading) {
                        Text(step.instructions)
                            .font(.headline)
                        
                        if step.distance > 0 {
                            Text(formatDistance(Measurement(value: step.distance, unit: UnitLength.meters)))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.advanceToNextStep()
                    }) {
                        Image(systemName: "arrow.right")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(viewModel.isOffRoute ? Color.red.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(10)
                
                if viewModel.isOffRoute {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text("Rerouting...")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                if !viewModel.remainingSteps.isEmpty {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Next:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(viewModel.remainingSteps.first?.instructions ?? "")
                                .font(.body)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            
            Button(action: {
                viewModel.cancelNavigation()
            }) {
                Text("End Navigation")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private func formatDistance(_ distance: Measurement<UnitLength>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        return formatter.string(from: distance)
    }
}

// MARK: - Info.plist Keys
// Add these to your Info.plist file:
// NSLocationWhenInUseUsageDescription - "We need your location to provide navigation services."
