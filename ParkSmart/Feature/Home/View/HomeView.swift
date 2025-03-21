

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
    
    // Add reference to NotificationManager
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            MapView()
                .environmentObject(carsViewModel)
                .environmentObject(mapViewModel)
                .environmentObject(sessionService)
                .environmentObject(groupsViewModel)
        }
  
        // Update the fullScreenCover to dismiss when a notification arrives
        .fullScreenCover(isPresented: Binding(
            get: { showNavigationView && !notificationManager.dismissAllSheets },
            set: { newValue in showNavigationView = newValue }
        )) {
            CombinedNavigationView(mapViewModel: mapViewModel)
        }
        
        // Add the RideAcceptedView sheet
        .sheet(isPresented: $notificationManager.showRideAcceptedView) {
            if let requestId = notificationManager.selectedRideRequestId {
                RideAcceptedView(requestId: requestId)
                    .environmentObject(sessionService)
            }
        }

        // Rest of your view remains the same
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
        
        // Listen for notifications to dismiss sheets
        .onChange(of: notificationManager.dismissAllSheets) { shouldDismiss in
            if shouldDismiss {
                showNavigationView = false
                showAccountView = false
                showGroupsView = false
                showMoreSheet = false
                showEditCar = false
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


//
//struct SearchBar: View {
//    @Binding var text: String
//    @State private var showNavigationView = false  // State for navigation view
//    @State private var showAccountView = false  // State for account view
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "magnifyingglass")
//                .foregroundColor(.gray)
//            
//            // Make the entire text field a button
//            Button(action: {
//                showNavigationView = true  // Show CombinedNavigationView when tapped
//            }) {
//                HStack {
//                    Text(text.isEmpty ? "Search locations..." : text)
//                        .foregroundColor(text.isEmpty ? .gray : .primary)
//                    Spacer()
//                }
//                .padding(8)
//                .background(Color.clear)
//            }
//
//            if !text.isEmpty {
//                Button(action: {
//                    self.text = ""
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(.gray)
//                }
//            }
//            
//
//        }
//        .padding(8)
//        .background(Color(.systemGray6))
//        .cornerRadius(10)
//        .fullScreenCover(isPresented: $showNavigationView) {
//            CombinedNavigationView(mapViewModel: MapViewModelImpl())
//        }
//        .sheet(isPresented: $showAccountView) {
//            AccountView()  // Display AccountView when tapped
//        }
//    }
//}




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

struct SubMainView: View {
    @Binding var searchText: String
    @State private var selectedTab = "Park"

    var body: some View {
        VStack {
            HStack {
                TabButton(title: "Park", imageName: "car.circle.fill", selectedTab: $selectedTab)
                TabButton(title: "Ride", imageName: "car.2.fill", selectedTab: $selectedTab)
            }
            .padding(.top, 10)

          
            
            // Show content based on selected tab
            if selectedTab == "Park" {
                ParkView()
            } else {
                ParkView()
            }
            
            Spacer()
        }
    }
}


struct ParkView: View {
    @StateObject private var mapViewModel = MapViewModelImpl()
    @State private var searchText = ""
    @State private var selectedParkingLot: ParkingLot? = nil
    @State private var showLotDetails: Bool = false
    @State private var lotsWithCounts: [ParkingLot] = []
    
    // Create sample polygons as MapOverlays
    var parkingLots: [ParkingLot] {
        return [
            ParkingLot(id: "lot23", name: "Lot 23", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23685, longitude: -77.42064),
                CLLocationCoordinate2D(latitude: 37.23660, longitude: -77.42034),
                CLLocationCoordinate2D(latitude: 37.23689, longitude: -77.41986),
                CLLocationCoordinate2D(latitude: 37.23720, longitude: -77.42005)
            ], color: .red),
            ParkingLot(id: "lot25", name: "Lot 25", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23787, longitude: -77.42061),
                CLLocationCoordinate2D(latitude: 37.23771, longitude: -77.42093),
                CLLocationCoordinate2D(latitude: 37.23717, longitude: -77.42048),
                CLLocationCoordinate2D(latitude: 37.23731, longitude: -77.42023)
            ], color: .yellow),
            ParkingLot(id: "lot26", name: "Lot 26", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23846, longitude: -77.42041),
                CLLocationCoordinate2D(latitude: 37.23821, longitude: -77.42027),
                CLLocationCoordinate2D(latitude: 37.23798, longitude: -77.42095),
                CLLocationCoordinate2D(latitude: 37.23824, longitude: -77.42107)
            ], color: .green),
            ParkingLot(id: "lot20", name: "Lot 20", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23624, longitude: -77.42054),
                CLLocationCoordinate2D(latitude: 37.23602, longitude: -77.42042),
                CLLocationCoordinate2D(latitude: 37.23610, longitude: -77.42015),
                CLLocationCoordinate2D(latitude: 37.23638, longitude: -77.42029)
            ], color: .red),
            ParkingLot(id: "lot22", name: "Lot 22", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23702, longitude: -77.41918),
                CLLocationCoordinate2D(latitude: 37.23713, longitude: -77.41901),
                CLLocationCoordinate2D(latitude: 37.23728, longitude: -77.41913),
                CLLocationCoordinate2D(latitude: 37.23721, longitude: -77.41923),
                CLLocationCoordinate2D(latitude: 37.23717, longitude: -77.41920),
                CLLocationCoordinate2D(latitude: 37.23686, longitude: -77.41967),
                CLLocationCoordinate2D(latitude: 37.23667, longitude: -77.41955),
                CLLocationCoordinate2D(latitude: 37.23683, longitude: -77.41921)
            ], color: .red),
            ParkingLot(id: "lot00", name: "Lot 00", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23676, longitude: -77.41765),
                CLLocationCoordinate2D(latitude: 37.23652, longitude: -77.41740),
                CLLocationCoordinate2D(latitude: 37.23616, longitude: -77.41804),
                CLLocationCoordinate2D(latitude: 37.23646, longitude: -77.41819)
            ], color: .red),
            ParkingLot(id: "jacplace", name: "Jac Place", available: false, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23711, longitude: -77.41709),
                CLLocationCoordinate2D(latitude: 37.23688, longitude: -77.41687),
                CLLocationCoordinate2D(latitude: 37.23699, longitude: -77.41669),
                CLLocationCoordinate2D(latitude: 37.23738, longitude: -77.41670)
            ], color: .red),
            ParkingLot(id: "owenshall", name: "Owens Hall", available: false, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23788, longitude: -77.41684),
                CLLocationCoordinate2D(latitude: 37.23759, longitude: -77.41776),
                CLLocationCoordinate2D(latitude: 37.23778, longitude: -77.41787),
                CLLocationCoordinate2D(latitude: 37.23807, longitude: -77.41692)
            ], color: .red),
            ParkingLot(id: "huntermac", name: "Hunter Mac", available: false, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23980, longitude: -77.41806),
                CLLocationCoordinate2D(latitude: 37.23987, longitude: -77.41783),
                CLLocationCoordinate2D(latitude: 37.24024, longitude: -77.41801),
                CLLocationCoordinate2D(latitude: 37.24016, longitude: -77.41823)
            ], color: .red),
            ParkingLot(id: "jessehall", name: "Jesse Hall", available: false, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23945, longitude: -77.41742),
                CLLocationCoordinate2D(latitude: 37.23896, longitude: -77.41717),
                CLLocationCoordinate2D(latitude: 37.23909, longitude: -77.41679),
                CLLocationCoordinate2D(latitude: 37.23942, longitude: -77.41695),
                CLLocationCoordinate2D(latitude: 37.23953, longitude: -77.41659),
                CLLocationCoordinate2D(latitude: 37.23912, longitude: -77.41636),
                CLLocationCoordinate2D(latitude: 37.23918, longitude: -77.41618),
                CLLocationCoordinate2D(latitude: 37.23960, longitude: -77.41639),
                CLLocationCoordinate2D(latitude: 37.23992, longitude: -77.41639),
                CLLocationCoordinate2D(latitude: 37.23993, longitude: -77.41621),
                CLLocationCoordinate2D(latitude: 37.24009, longitude: -77.41623),
                CLLocationCoordinate2D(latitude: 37.24009, longitude: -77.41675),
                CLLocationCoordinate2D(latitude: 37.23972, longitude: -77.41658)
            ], color: .red),
            ParkingLot(id: "backlot", name: "Back Lot", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23466, longitude: -77.42005),
                CLLocationCoordinate2D(latitude: 37.23444, longitude: -77.41991),
                CLLocationCoordinate2D(latitude: 37.23422, longitude: -77.42057),
                CLLocationCoordinate2D(latitude: 37.23446, longitude: -77.42065)
            ], color: .red),
            ParkingLot(id: "quad2", name: "Quad 2", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23619, longitude: -77.42204),
                CLLocationCoordinate2D(latitude: 37.23574, longitude: -77.42156),
                CLLocationCoordinate2D(latitude: 37.23559, longitude: -77.42182),
                CLLocationCoordinate2D(latitude: 37.23602, longitude: -77.42230)
            ], color: .red),
            ParkingLot(id: "lot 14", name: "lot 14", available: false, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23851, longitude: -77.41717),
                CLLocationCoordinate2D(latitude: 37.23846, longitude: -77.41735),
                CLLocationCoordinate2D(latitude: 37.23822, longitude: -77.41724),
                CLLocationCoordinate2D(latitude: 37.23828, longitude: -77.41705)
            ], color: .red),
            ParkingLot(id: "screw12", name: "Screw 12", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.23851, longitude: -77.41680),
                CLLocationCoordinate2D(latitude: 37.23846, longitude: -77.41693),
                CLLocationCoordinate2D(latitude: 37.23757, longitude: -77.41651),
                CLLocationCoordinate2D(latitude: 37.23767, longitude: -77.41633),
                CLLocationCoordinate2D(latitude: 37.23786, longitude: -77.41641),
                CLLocationCoordinate2D(latitude: 37.23829, longitude: -77.41636),
                CLLocationCoordinate2D(latitude: 37.23827, longitude: -77.41652),
                CLLocationCoordinate2D(latitude: 37.23840, longitude: -77.41659),
                CLLocationCoordinate2D(latitude: 37.23835, longitude: -77.41673),
                CLLocationCoordinate2D(latitude: 37.23844, longitude: -77.41678)
            ], color: .red),
            ParkingLot(id: "agri", name: "Agriculture", available: true, coordinates: [
                CLLocationCoordinate2D(latitude: 37.24047, longitude: -77.41776),
                CLLocationCoordinate2D(latitude: 37.24043, longitude: -77.41790),
                CLLocationCoordinate2D(latitude: 37.23992, longitude: -77.41766),
                CLLocationCoordinate2D(latitude: 37.23999, longitude: -77.41746),
                CLLocationCoordinate2D(latitude: 37.24040, longitude: -77.41767),
                CLLocationCoordinate2D(latitude: 37.24038, longitude: -77.41773)
            ], color: .red)
        ]
    }
    
    // Calculate centroid for annotations
    func calculateCentroid(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        var latitude: Double = 0
        var longitude: Double = 0
        
        let count = Double(coordinates.count)
        for coordinate in coordinates {
            latitude += coordinate.latitude
            longitude += coordinate.longitude
        }
        
        return CLLocationCoordinate2D(latitude: latitude / count, longitude: longitude / count)
    }
    
    var body: some View {
        VStack(spacing: 0) {

            
            // List of parking lots
            List {
                ForEach(lotsWithCounts.isEmpty ? parkingLots : lotsWithCounts) { lot in
                    Button {
                        selectedParkingLot = lot
                        showLotDetails = true
                    } label: {
                        HStack {
                            Circle()
                                .fill(lot.dynamicColor)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading) {
                                Text(lot.name)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("\(lot.availableSpots) of \(lot.totalSpots) spots available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(statusText(for: lot))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(lot.dynamicColor.opacity(0.2))
                                .foregroundColor(lot.dynamicColor)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .onAppear {
            mapViewModel.getCurrentLocation()
            Task {
                await mapViewModel.fetchParkingSpots()
                // Update the lots with counts after fetching spots
                lotsWithCounts = mapViewModel.countSpotsInLots(parkingSpots: mapViewModel.parkingSpots,
                                                             lots: parkingLots)
            }
        }
        .onChange(of: mapViewModel.parkingSpots) { _, newSpots in
            lotsWithCounts = mapViewModel.countSpotsInLots(parkingSpots: newSpots,
                                                         lots: parkingLots)
        }
        .animation(.spring(), value: showLotDetails)
    }
    
    // Helper function to display status text based on availability
    private func statusText(for lot: ParkingLot) -> String {
        guard lot.totalSpots > 0 else { return "Unknown" }
        
        let ratio = Double(lot.availableSpots) / Double(lot.totalSpots)
        
        switch ratio {
        case 0.75...1.0:
            return "Many Spots"
        case 0.5..<0.75:
            return "Available"
        case 0.25..<0.5:
            return "Limited"
        default:
            return "Full"
        }
    }
}


// MARK: - Top Navigation Tabs
struct TabButton: View {
    let title: String
    let imageName: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            selectedTab = title
        }) {
            VStack {
                Image(systemName: imageName)
                    .font(.system(size: 20))
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(selectedTab == title ? .black : .gray)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
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
    @State private var showingTurnByTurnNavigation = false
    @State private var showingWalletView = false
    @State private var showPointAlert = false
    @State private var showMarketMessage = false
    @State private var alertMessage = ""
    @State private var selectedTab: String = "Park"
    
    @ObservedObject private var notificationManager = NotificationManager.shared
    @StateObject private var userViewModel = UserViewModel()

    private var initialDestination: CLLocationCoordinate2D?
    private var destinationName: String?

    struct LocationResult: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
    }

    init(mapViewModel: MapViewModelImpl = MapViewModelImpl(),
         initialDestination: CLLocationCoordinate2D? = nil,
         destinationName: String? = nil) {
        _mapViewModel = StateObject(wrappedValue: mapViewModel)
        self.initialDestination = initialDestination
        self.destinationName = destinationName
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Top tabs
                HStack {
//                    Button(action: {
//                        dismiss()
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(.primary)
//                            .padding()
//                    }
//                    
//                    Spacer()
                    
                    // Tab buttons
                    HStack(spacing: 0) {
                        TabButton(title: "Park", imageName: "parkingsign", selectedTab: $selectedTab)
                        TabButton(title: "Requests", imageName: "car", selectedTab: $selectedTab)
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
//                    Spacer()
//                    
//                    Button(action: {
//                        dismiss()
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(.primary)
//                            .padding()
//                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Search bar
                if !showingNavigation {
                    SearchBar2(text: $searchText) {}
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                } else if let location = selectedLocation {
                    HStack {
                        Button(action: {
                            showingNavigation = false
                            selectedLocation = nil
                            currentRoute = nil
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.primary)
                                .padding()
                        }
                        
                        Text(location.title)
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Main content
                if !searchText.isEmpty && !showingNavigation {
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
                } else if showingNavigation {
                    // Navigation view
                    ScrollView {
                        VStack(spacing: 0) {
                            // Map in RoundedRectangle
                            if isMapReady {
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 3)
                                        .overlay(
                                            LocationMapView(route: currentRoute,
                                                          destination: selectedLocation?.coordinate ??
                                                                     CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                                                .cornerRadius(12)
                                        )
                                    
                                    // Overlay: Travel Time & Distance at the Bottom
                                    if let route = currentRoute {
                                        HStack {
                                            Text("\(Int(route.expectedTravelTime / 60)) min")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)

                                            Text("\(String(format: "%.1f", route.distance / 1609.34)) mi")
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(10)
                                        .padding(.bottom, 10)
                                    }
                                }
                                .frame(height: UIScreen.main.bounds.height * 0.4)
                                .padding()
                            }
                            
                            // SameDestinationRequestsView
                            if let destination = selectedLocation?.coordinate {
                                SameDestinationRequestsView(userSelectedDestination: destination)
                                    .frame(height: 300)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                            
                            // Add spacing to ensure content scrolls above the navigation controls
                            Spacer().frame(height: 130)
                        }
                    }
                } else {
                    // Default tab content
                    TabView(selection: $selectedTab) {
                        // Park tab content
                        ParkView()
                            .tag("Park")
                        
                        // Ride tab content
                        DriverRideRequestsView()
                            .tag("Requests")
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            
            // Fixed navigation controls at the bottom
            if showingNavigation, let route = currentRoute {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button(action: {
                            if userViewModel.points < 20 {
                                alertMessage = "You need at least 20 points to use the Find Ride feature."
                                showPointAlert = true
                            } else {
                                showMarketMessage = true
                            }
                        }) {
                            Text("Find a ride")
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
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(radius: 5, y: -3)
                )
            }
        }
        .fullScreenCover(isPresented: $showMarketMessage) {
            FindARideView(destination: selectedLocation?.coordinate, route: currentRoute)
                .environmentObject(TipsStore())
        }
        .fullScreenCover(isPresented: $showingWalletView) {
            AddMoneyWalletView().environmentObject(TipsStore())
        }
        .fullScreenCover(isPresented: $showingTurnByTurnNavigation) {
            if let route = currentRoute {
                TurnByTurnNavigationView(route: route)
            }
        }
        .alert(isPresented: $showPointAlert) {
            Alert(
                title: Text("Insufficient Points"),
                message: Text(alertMessage),
                primaryButton: .default(Text("OK")) {
                    showingWalletView = true
                },
                secondaryButton: .cancel()
            )
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

                // If we have an initial destination, set it up automatically
                if let destination = initialDestination, let name = destinationName {
                    let result = LocationResult(
                        title: name,
                        subtitle: "Parking Lot",
                        coordinate: destination
                    )
                    selectedLocation = result
                    showingNavigation = true
                    calculateRoute(to: destination)
                }
            }
        }
        .onChange(of: notificationManager.dismissAllSheets) { shouldDismiss in
            if shouldDismiss {
                dismiss()
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
        request.requestsAlternateRoutes = true

        MKDirections(request: request).calculate { response, error in
            DispatchQueue.main.async {
                if let routes = response?.routes {
                    let shortestRoute = routes.min(by: { $0.distance < $1.distance })
                    self.currentRoute = shortestRoute
                }
            }
        }
    }
}

// RideView placeholder - implement this view for ride-sharing functionality
struct RideView: View {
    var body: some View {
        VStack {
            Text("Ride Sharing")
                .font(.title)
                .padding()
            
            Text("Find rides to your destination")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}


struct SameDestinationRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var rideRequests: [RideRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var selectedRequest: RideRequest? = nil
    @State private var showingRequestDetail = false
    @State private var selectedDestination: GeoPoint? = nil
    @State private var destinationOptions: [DestinationOption] = []
    @State private var currentPage = 0

    var userSelectedDestination: CLLocationCoordinate2D?
    
    struct DestinationOption: Identifiable {
        let id = UUID()
        let destination: GeoPoint
        let displayName: String
        let count: Int
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                
                    
                    Spacer()
                    Text("Select a tag along")
                    Spacer()
                
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Loading ride requests...")
                    Spacer()
                } else if selectedDestination == nil {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Select a destination")
                            .font(.headline)
                        Text("Choose from common destinations above")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if filteredRequests.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No matching ride requests")
                            .font(.headline)
                        Text("No one is currently requesting a ride to this destination")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {

                    VStack {
                        TabView(selection: $currentPage) {
                            ForEach(filteredRequests.indices, id: \.self) { index in
                                rideRequestCard(filteredRequests[index])
                                    .onTapGesture {
                                        selectedRequest = filteredRequests[index]
                                        showingRequestDetail = true
                                    }
                                    .padding(.horizontal, 16)
                                    .tag(index) // Assign tag for tracking
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(.page)

                        // Page Indicator
                        if filteredRequests.count > 1 {
                            HStack {
                                ForEach(0..<filteredRequests.count, id: \.self) { index in
                                    Circle()
                                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .onChange(of: currentPage) { _ in
                        // Update logic if needed when the page changes
                    }


                    .refreshable {
                        loadRideRequests()
                    }

                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred"), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingRequestDetail) {
                if let request = selectedRequest {
                    RideRequestDetailView(request: request)
                }
            }
            .onAppear {
                // Request location permission when view appears
                locationManager.requestLocationAuthorization()
                // Give location services a moment to initialize before loading requests
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    loadRideRequests()
                    
                    // If a destination was passed, try to set it as the filter
                    if let userDest = userSelectedDestination {
                        // Convert CLLocationCoordinate2D to GeoPoint for comparison
                        let userDestGeoPoint = GeoPoint(latitude: userDest.latitude, longitude: userDest.longitude)
                        
                        // First try to find an exact match
                        if let matchingOption = destinationOptions.first(where: {
                            isEqualLocation($0.destination, userDestGeoPoint)
                        }) {
                            selectedDestination = matchingOption.destination
                        } else if !destinationOptions.isEmpty {
                            // If no exact match, find the closest destination
                            selectedDestination = findClosestDestination(to: userDest)
                        }
                    }
                }
            }
        }
    }
    

    
    private func destinationButton(_ option: DestinationOption) -> some View {
        Button(action: {
            if selectedDestination != nil && isEqualLocation(selectedDestination!, option.destination) {
                // Deselect if already selected
                selectedDestination = nil
            } else {
                selectedDestination = option.destination
            }
        }) {
            HStack {
                Text(option.displayName)
                    .font(.subheadline)
                
                Text("\(option.count)")
                    .font(.caption)
                    .padding(5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedDestination != nil && isEqualLocation(selectedDestination!, option.destination)
                ? Color.blue
                : Color.blue.opacity(0.1)
            )
            .foregroundColor(
                selectedDestination != nil && isEqualLocation(selectedDestination!, option.destination)
                ? .white
                : .blue
            )
            .cornerRadius(20)
        }
    }
    
    private var filteredRequests: [RideRequest] {
        guard let selectedDestination = selectedDestination else {
            return []
        }
        
        return rideRequests.filter { request in
            isEqualLocation(request.destination, selectedDestination)
        }.sorted { request1, request2 in
            if let userLocation = locationManager.location {
                let dist1 = calculateDistance(from: userLocation.coordinate, to: request1.pickupCoordinate)
                let dist2 = calculateDistance(from: userLocation.coordinate, to: request2.pickupCoordinate)
                return dist1 < dist2
            }
            return request1.timestamp > request2.timestamp
        }
    }
    
    private func rideRequestCard(_ request: RideRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row with points and distance
            HStack(alignment: .top) {
                Text("\(request.pointsOffered) points")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                
            }
            
            // Route details
            HStack(alignment: .top) {
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 84)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        
                        HStack {
                            Text("Pickup Location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let userLocation = locationManager.location {
                                // Distance to pickup location
                                let pickupDistance = calculateDistance(from: userLocation.coordinate, to: request.pickupCoordinate)
                                Text(String(format: "%.1f mi away", pickupDistance))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                                      
                            }
                        }
                     
                        
                        
                        Text(request.pickupAddress?.components(separatedBy: ",").first ?? "Loading pickup address...")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let fullAddress = request.pickupAddress, let firstComma = fullAddress.firstIndex(of: ",") {
                            Text(String(fullAddress[fullAddress.index(after: firstComma)...]).trimmingCharacters(in: .whitespaces))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        
                        HStack {
                            
                            Text("Destination")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Distance between driver's destination and rider's destination
                            if let userDestination = userSelectedDestination {
                                let destinationDistance = calculateDistance(from: userDestination, to: request.destinationCoordinate)
                                Text(String(format: "%.1f mi from yours", destinationDistance))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                      
                        
                        Text(request.destinationAddress?.components(separatedBy: ",").first ?? "Loading destination address...")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let fullAddress = request.destinationAddress, let firstComma = fullAddress.firstIndex(of: ",") {
                            Text(String(fullAddress[fullAddress.index(after: firstComma)...]).trimmingCharacters(in: .whitespaces))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.leading, 8)

                
                Spacer()
             
            }
            
            // Rider name
            Text("Rider: \(request.riderName)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    let addressManager = AddressManager()
    
    private func loadRideRequests() {
        guard let userLocation = locationManager.location else {
            errorMessage = "Unable to get your location."
            showError = true
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("rideRequests")
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Failed to load ride requests: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.rideRequests = []
                    self.destinationOptions = []
                    return
                }
                
                // Parse ride requests
                let requests = documents.compactMap { document -> RideRequest? in
                    guard let userId = document.data()["userId"] as? String,
                          let riderName = document.data()["riderName"] as? String,
                          let pickupLocation = document.data()["pickupLocation"] as? GeoPoint,
                          let destination = document.data()["destination"] as? GeoPoint,
                          let timestamp = document.data()["timestamp"] as? Timestamp,
                          let status = document.data()["status"] as? String,
                          let pointsOffered = document.data()["pointsOffered"] as? Int,
                          let estimatedDistance = document.data()["estimatedDistance"] as? Double,
                          let estimatedDuration = document.data()["estimatedDuration"] as? Double else {
                        return nil
                    }
                    
                    return RideRequest(
                        id: document.documentID,
                        userId: userId,
                        riderName: riderName,
                        pickupLocation: pickupLocation,
                        destination: destination,
                        timestamp: timestamp.dateValue(),
                        status: status,
                        pointsOffered: pointsOffered,
                        estimatedDistance: estimatedDistance,
                        estimatedDuration: estimatedDuration
                    )
                }
                
                self.rideRequests = requests
                
                // Generate destination options
                var destinationCounts: [String: (GeoPoint, Int)] = [:]
                var destinationNames: [String: String] = [:]
                
                for index in requests.indices {
                              addressManager.fetchAddress(for: requests[index].pickupCoordinate) { address in
                                  DispatchQueue.main.async {
                                      self.rideRequests[index].pickupAddress = address ?? "Unknown Address"
                                  }
                              }
                              
                              addressManager.fetchAddress(for: requests[index].destinationCoordinate) { address in
                                  DispatchQueue.main.async {
                                      self.rideRequests[index].destinationAddress = address ?? "Unknown Address"
                                  }
                              }
                          }
                
                // This would ideally come from a geocoder, but for now use a simple approach
                for request in requests {
                    let key = "\(request.destination.latitude),\(request.destination.longitude)"
                    
                    if let existing = destinationCounts[key] {
                        destinationCounts[key] = (existing.0, existing.1 + 1)
                    } else {
                        destinationCounts[key] = (request.destination, 1)
                        
                        // Generate a simple name based on coordinate
                        // In a real app, you'd use reverse geocoding to get actual names
                        let lat = request.destination.latitude
                        let lng = request.destination.longitude
                        destinationNames[key] = String(format: "Destination %.2f,%.2f", lat, lng)
                    }
                }
                
                // Convert to options
                self.destinationOptions = destinationCounts.map { key, value in
                    DestinationOption(
                        destination: value.0,
                        displayName: destinationNames[key] ?? "Unknown",
                        count: value.1
                    )
                }
                .sorted { $0.count > $1.count }
                
                // Reset selection if needed
                if let userDest = userSelectedDestination {
                    let userDestGeoPoint = GeoPoint(latitude: userDest.latitude, longitude: userDest.longitude)
                    
                    // First try to find an exact match
                    if let matchingOption = self.destinationOptions.first(where: {
                        isEqualLocation($0.destination, userDestGeoPoint)
                    }) {
                        self.selectedDestination = matchingOption.destination
                    } else if !self.destinationOptions.isEmpty {
                        // If no exact match, find the closest destination
                        self.selectedDestination = findClosestDestination(to: userDest)
                    }
                }
            }
    }
    
    private func findClosestDestination(to coordinate: CLLocationCoordinate2D) -> GeoPoint? {
        guard !destinationOptions.isEmpty else { return nil }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Sort destinations by distance to the target coordinate
        let sortedDestinations = destinationOptions.sorted { option1, option2 in
            let location1 = CLLocation(latitude: option1.destination.latitude, longitude: option1.destination.longitude)
            let location2 = CLLocation(latitude: option2.destination.latitude, longitude: option2.destination.longitude)
            
            return location1.distance(from: targetLocation) < location2.distance(from: targetLocation)
        }
        
        // Return the closest destination
        return sortedDestinations.first?.destination
    }
    
    private func isEqualLocation(_ geoPoint1: GeoPoint, _ geoPoint2: GeoPoint) -> Bool {
        // Consider locations equal if they are within ~10 meters
        let tolerance = 0.0001 // Roughly 10 meters at the equator
        return abs(geoPoint1.latitude - geoPoint2.latitude) < tolerance &&
               abs(geoPoint1.longitude - geoPoint2.longitude) < tolerance
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceInMeters = fromLocation.distance(from: toLocation)
        return distanceInMeters / 1609.34 // Convert to miles
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}
//import SwiftUI
//
//struct FindARideView: View {
//    @Environment(\.dismiss) var dismiss
//
//    var body: some View {
//        VStack {
//            // X button at the top right
//            HStack {
//                Spacer() // Pushes the button to the right
//                Button(action: {
//                    dismiss()
//                }) {
//                    Image(systemName: "xmark")
//                        .font(.title2)
//                        .foregroundColor(.black)
//                        .padding()
//                }
//            }
//            .padding(.trailing) // Add some right padding
//
//            Spacer()
//            
//            Text("Payment Methods View")
//                .font(.title)
//            
//            Spacer()
//        }
//        .padding(.top) // Add padding to push content down
//        .background(Color.white.edgesIgnoringSafeArea(.all))
//    }
//}



import SwiftUI

struct AddMoneyWalletView: View {
    @StateObject private var userViewModel = UserViewModel() // Use the ViewModel to fetch points and user info
    @EnvironmentObject private var store: TipsStore
    @State private var showSubscriptionView = false
    @State private var showThanks = false
    @Environment(\.presentationMode) private var presentationMode  // To dismiss the view

    var body: some View {
        VStack(spacing: 20) {
            // Dismiss Button (X) above Available Points
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()  // Dismiss the view
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .font(.title)
                }
            }
            .padding(.trailing)

            // Main content
            Text("Available Points")
                .font(.headline)
                .foregroundColor(.gray)
            
            // Bind the real points from UserViewModel
            Text("\(userViewModel.points, specifier: "%.2f")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            // Card View
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 200)
                    .shadow(radius: 5)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Text("**** **** **** ****")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Card Holder")
                            .font(.caption)
                            .foregroundColor(.black)
                        // Display the full name here
                        Text("\(userViewModel.firstName) \(userViewModel.lastName)")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Exp Date")
                                .font(.caption)
                                .foregroundColor(.black)
                            Text("∞")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .padding()
            }
            .frame(height: 140)
            
            Button(action: {
                showSubscriptionView.toggle()
            }) {
                Text("+ Add More Points")
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1))
            }
            .padding(.horizontal)
            
            // Transactions Section
            VStack(alignment: .leading) {
                Text("Transactions")
                    .font(.headline)
                    .foregroundColor(.white)
                List {
                    TransactionRow(title: "Central Parking", amount: -25)
                    TransactionRow(title: "ABC Parking", amount: -35)
                }
                .listStyle(PlainListStyle())
                .frame(height: 160)
            }
        }
        .padding()
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .overlay {
            if showSubscriptionView {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        showSubscriptionView.toggle()
                    }
                subscriptionView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if showThanks {
                thankYouView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showSubscriptionView)
        .animation(.spring(), value: showThanks)
        .onChange(of: store.action) { action in
            if action == .successful {
                showSubscriptionView = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showThanks.toggle()
                }
                store.reset()
            }
        }
        .alert(isPresented: $store.hasError, error: store.error) { }
    }
}




private extension AddMoneyWalletView {
    var subscriptionView: some View {
        VStack(spacing: 8) {
            Text("Add More Points")
                .font(.system(.title2, design: .rounded).bold())
                .multilineTextAlignment(.center)
            
            Button {
                showRewardedAd()
            } label: {
                HStack {
                    Text("Watch Ad for Points")
                    Image(systemName: "video.fill")
                        .foregroundColor(.yellow)
                }
                .font(.system(.title3, design: .rounded).bold())
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            ForEach(store.items) { item in
                configureProductVw(item)
            }
        }
        .padding(16)
        .background(Color("card-background"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(8)
    }

    // Function to trigger the ad
    func showRewardedAd() {
        // Call your ad SDK to show a rewarded ad
        // Example for AdMob:
//        RewardedAdService.shared.showAd { success in
//            if success {
//                store.addPoints(10) // Example: Grant 10 points
//            }
//        }
    }

    
    var thankYouView: some View {
        VStack(spacing: 8) {
            Text("Thank You 💕")
                .font(.system(.title2, design: .rounded).bold())
                .multilineTextAlignment(.center)
            
            Text("Your purchase was successful. Enjoy your points!")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            Button {
                showThanks.toggle()
            } label: {
                Text("Close")
                    .font(.system(.title3, design: .rounded).bold())
                    .tint(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(Color("card-background"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 8)
    }
    
    func configureProductVw(_ item: Product) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(.title3, design: .rounded).bold())
                Text(item.description)
                    .font(.system(.callout, design: .rounded).weight(.regular))
            }
            Spacer()
            Button(item.displayPrice) {
                Task {
                    await store.purchase(item)
                }
            }
            .tint(.blue)
            .buttonStyle(.bordered)
            .font(.callout.bold())
        }
        .padding(16)
        .background(Color("cell-background"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

import Foundation
import CoreLocation

struct ParkingSpot: Identifiable, Equatable {
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

    // Equatable conformance
    static func ==(lhs: ParkingSpot, rhs: ParkingSpot) -> Bool {
        return lhs.id == rhs.id
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
import StoreKit

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
