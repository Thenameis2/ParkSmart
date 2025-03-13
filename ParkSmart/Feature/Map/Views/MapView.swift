

import SwiftUI
import MapKit

import SwiftUI
import MapKit

import SwiftUI
import MapKit

import SwiftUI
import MapKit
import _MapKit_SwiftUI
import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var groupsViewModel: GroupsViewModelImpl
    
    @State private var searchText = ""
    @State private var showNavigationView = false
    @StateObject private var navigationManager = NavigationManager()
    @State private var showGroupsView = false
    @State private var showAccountView = false
    @State private var showAccountMenu = false
    
    @State private var lotsWithCounts: [ParkingLot] = []
    @State private var selectedParkingLot: ParkingLot? = nil
        @State private var showLotDetails: Bool = false
    
    // Create polygons as MapOverlays for map content builder
    var polygonOverlays: [ParkingLot] {
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
    
    // Binding for map region from MapViewModel
    private var region: Binding<MKCoordinateRegion> {
        Binding {
            mapViewModel.region
        } set: { region in
            DispatchQueue.main.async {
                mapViewModel.region = region
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Combined Map with polygons and annotations
            Map {
                          // Add all polygon overlays
                          ForEach(lotsWithCounts) { lot in
                              MapPolygon(coordinates: lot.coordinates)
                                  .stroke(lot.color, lineWidth: 1)
                                  .foregroundStyle(lot.color.opacity(0.3))
                                  .mapOverlayLevel(level: .aboveRoads)
                              
                              // Modified annotation to handle taps
                              Annotation("\(lot.name) (\(lot.availableSpots)/\(lot.totalSpots))",
                                        coordinate: calculateCentroid(coordinates: lot.coordinates)) {
                                  Button {
                                      selectedParkingLot = lot
                                      showLotDetails = true
                                  } label: {
                                      ZStack {
                                          Circle()
                                              .fill(lot.color)
                                              .frame(width: 20, height: 20)
                                          Text("\(lot.availableSpots)")
                                              .font(.caption)
                                              .foregroundColor(.white)
                                      }
                                  }
                              }
                          }
                          
                          // Add user location
                          UserAnnotation()
                      }
            .mapStyle(mapViewModel.mapStyle)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .gesture(DragGesture().onChanged({ _ in
                mapViewModel.isCurrentLocationClicked = false
            }))
          
            .onAppear {
                    mapViewModel.getCurrentLocation()
                    Task {
                        await mapViewModel.fetchParkingSpots()
                        // Update the lots with counts after fetching spots
                        lotsWithCounts = mapViewModel.countSpotsInLots(parkingSpots: mapViewModel.parkingSpots,
                                                                     lots: polygonOverlays)
                    }
                }
                // Add this to update the counts when parking spots change
                .onChange(of: mapViewModel.parkingSpots) { _, newSpots in
                    lotsWithCounts = mapViewModel.countSpotsInLots(parkingSpots: newSpots,
                                                                 lots: polygonOverlays)
                }
            
            // Profile & Menu buttons
            HStack {
                // Profile button on the left
                VStack {
                    Button {
                        showAccountView.toggle()
                    } label: {
                        Image(systemName: "person.circle")
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.leading, 5)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    // Map style picker
                    Menu {
                        Button {
                            mapViewModel.mapStyle = .standard
                        } label: {
                            Label("Standard", systemImage: "map")
                        }
                        
                        Button {
                            mapViewModel.mapStyle = .hybrid
                        } label: {
                            Label("Hybrid", systemImage: "map.fill")
                        }
                        
                        Button {
                            mapViewModel.mapStyle = .imagery
                        } label: {
                            Label("Satellite", systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "map")
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 2)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.trailing, 5)
                .padding(.top, 50)
            }
            .padding(.top, 10)
            
            // Bottom sheet search bar
            VStack {
                            Spacer()
                            
                            // Parking lot details card
                            if showLotDetails, let lot = selectedParkingLot {
                                LotDetailsCard(lot: lot, isShowing: $showLotDetails)
                                    .transition(.move(edge: .bottom))
                                    .zIndex(1)
                            }
                            
                            // Bottom sheet search bar
                            BottomSheetSearchBar(searchText: $searchText, showNavigationView: $showNavigationView)
                        }
                        .ignoresSafeArea(.keyboard)
                        .animation(.spring(), value: showLotDetails)
        }
        .sheet(isPresented: $showAccountView) {
            AccountView()
        }
        .fullScreenCover(isPresented: $showNavigationView) {
            CombinedNavigationView(mapViewModel: MapViewModelImpl())
        }
    }
}

struct LotDetailsCard: View {
    let lot: ParkingLot
    @Binding var isShowing: Bool
    
    @State private var showNavigationView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lot.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    isShowing = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Available Spots")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(lot.availableSpots)/\(lot.totalSpots)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Status indicator
                VStack {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Circle()
                            .fill(lot.dynamicColor)
                            .frame(width: 10, height: 10)
                        
                        Text(statusText(for: lot))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Button {
                        showNavigationView = true
                    } label: {
                        Text("Navigate")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .fullScreenCover(isPresented: $showNavigationView) {
                    CombinedNavigationView(initialDestination: calculateCentroid(coordinates: lot.coordinates), destinationName: lot.name)
                }
            }
            
            // Add this function to calculate centroid
            private func calculateCentroid(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
                var latitude: Double = 0
                var longitude: Double = 0
                
                let count = Double(coordinates.count)
                for coordinate in coordinates {
                    latitude += coordinate.latitude
                    longitude += coordinate.longitude
                }
                
                return CLLocationCoordinate2D(latitude: latitude / count, longitude: longitude / count)
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

// Model for parking lots
struct ParkingLot: Identifiable {
    let id: String
    let name: String
    let available: Bool
    let coordinates: [CLLocationCoordinate2D]
    var color: Color  // Will be dynamically set
    var availableSpots: Int = 0
    var totalSpots: Int = 0
    
    // Computed property to determine color based on availability ratio
    var dynamicColor: Color {
        guard totalSpots > 0 else { return .gray }
        
        let ratio = Double(availableSpots) / Double(totalSpots)
        
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
}



struct BottomSheetSearchBar: View {
    @Binding var searchText: String
    @Binding var showNavigationView: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
          
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Button(action: {
                    showNavigationView = true
                }) {
                    HStack {
                        Text(searchText.isEmpty ? "Search locations..." : searchText)
                            .foregroundColor(searchText.isEmpty ? .gray : .primary)
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 0)
    }
}



struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        let mapViewModel = MapViewModelImpl()
        let sessionService = SessionServiceImpl()
        
        MapView()
            .environmentObject(carsViewModel)
            .environmentObject(sessionService)
            .environmentObject(mapViewModel)
        
    }
}

struct MoreInfoView: View {
    @Binding var showAccountView: Bool
    @Binding var showGroupsView: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Groups")) {
                    HStack {
                        Button { showGroupsView = true } label: {
                            Label("Groups", systemImage: "person.3")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section(header: Text("Account")) {
                    HStack {
                        Button { showAccountView = true } label: {
                            Label("Account", systemImage: "person.crop.circle")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button {
                            if let url = URL(string: "mailto:help@support.com?subject=Help and Feedback"),
                               UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Help & Feedback", systemImage: "questionmark.circle")
                        }
                    }
                }
            }
            .navigationTitle("More")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAccountView = false
                        showGroupsView = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}






struct refMapView: View {
    
    // Polygon coordinates
    let lot23: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23685, longitude: -77.42064),
        CLLocationCoordinate2D(latitude: 37.23660, longitude: -77.42034),
        CLLocationCoordinate2D(latitude: 37.23689, longitude: -77.41986),
        CLLocationCoordinate2D(latitude: 37.23720, longitude: -77.42005)
    ]
    
    let lot25: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23787, longitude: -77.42061),
        CLLocationCoordinate2D(latitude: 37.23771, longitude: -77.42093),
        CLLocationCoordinate2D(latitude: 37.23717, longitude: -77.42048),
        CLLocationCoordinate2D(latitude: 37.23731, longitude: -77.42023)
    ]
    
    let lot26: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23846, longitude: -77.42041),
        CLLocationCoordinate2D(latitude: 37.23821, longitude: -77.42027),
        CLLocationCoordinate2D(latitude: 37.23798, longitude: -77.42095),
        CLLocationCoordinate2D(latitude: 37.23824, longitude: -77.42107)
    ]
    
    let lot20: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23624, longitude: -77.42054),
        CLLocationCoordinate2D(latitude: 37.23602, longitude: -77.42042),
        CLLocationCoordinate2D(latitude: 37.23610, longitude: -77.42015),
        CLLocationCoordinate2D(latitude: 37.23638, longitude: -77.42029)
    ]
    
    let lot00: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23676, longitude: -77.41765),
        CLLocationCoordinate2D(latitude: 37.23652, longitude: -77.41740),
        CLLocationCoordinate2D(latitude: 37.23616, longitude: -77.41804),
        CLLocationCoordinate2D(latitude: 37.23646, longitude: -77.41819)
    ]
    
    let jacplace: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23711, longitude: -77.41709),
        CLLocationCoordinate2D(latitude: 37.23688, longitude: -77.41687),
        CLLocationCoordinate2D(latitude: 37.23699, longitude: -77.41669),
        CLLocationCoordinate2D(latitude: 37.23738, longitude: -77.41670)
    ]
    
    let owenshall: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23788, longitude: -77.41684),
        CLLocationCoordinate2D(latitude: 37.23759, longitude: -77.41776),
        CLLocationCoordinate2D(latitude: 37.23778, longitude: -77.41787),
        CLLocationCoordinate2D(latitude: 37.23807, longitude: -77.41692)
    ]
    
    let huntermac: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23980, longitude: -77.41806),
        CLLocationCoordinate2D(latitude: 37.23987, longitude: -77.41783),
        CLLocationCoordinate2D(latitude: 37.24024, longitude: -77.41801),
        CLLocationCoordinate2D(latitude: 37.24016, longitude: -77.41823)
    ]
    
    let jessehall: [CLLocationCoordinate2D] = [
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
    ]
    
    let lot22: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23702, longitude: -77.41918),
        CLLocationCoordinate2D(latitude: 37.23713, longitude: -77.41901),
        CLLocationCoordinate2D(latitude: 37.23728, longitude: -77.41913),
        CLLocationCoordinate2D(latitude: 37.23721, longitude: -77.41923),
        CLLocationCoordinate2D(latitude: 37.23717, longitude: -77.41920),
        CLLocationCoordinate2D(latitude: 37.23686, longitude: -77.41967),
        CLLocationCoordinate2D(latitude: 37.23667, longitude: -77.41955),
        CLLocationCoordinate2D(latitude: 37.23683, longitude: -77.41921)
    ]
    
    let backlot: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23466, longitude: -77.42005),
        CLLocationCoordinate2D(latitude: 37.23444, longitude: -77.41991),
        CLLocationCoordinate2D(latitude: 37.23422, longitude: -77.42057),
        CLLocationCoordinate2D(latitude: 37.23446, longitude: -77.42065)
    ]
    
    let quad2: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23619, longitude: -77.42204),
        CLLocationCoordinate2D(latitude: 37.23574, longitude: -77.42156),
        CLLocationCoordinate2D(latitude: 37.23559, longitude: -77.42182),
        CLLocationCoordinate2D(latitude: 37.23602, longitude: -77.42230)
    ]
    
    let handicapO: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.23851, longitude: -77.41717),
        CLLocationCoordinate2D(latitude: 37.23846, longitude: -77.41735),
        CLLocationCoordinate2D(latitude: 37.23822, longitude: -77.41724),
        CLLocationCoordinate2D(latitude: 37.23828, longitude: -77.41705)
    ]
    
    let screw12: [CLLocationCoordinate2D] = [
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
    ]
    
    let agri: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.24047, longitude: -77.41776),
        CLLocationCoordinate2D(latitude: 37.24043, longitude: -77.41790),
        CLLocationCoordinate2D(latitude: 37.23992, longitude: -77.41766),
        CLLocationCoordinate2D(latitude: 37.23999, longitude: -77.41746),
        CLLocationCoordinate2D(latitude: 37.24040, longitude: -77.41767),
        CLLocationCoordinate2D(latitude: 37.24038, longitude: -77.41773),
    ]
    
    
    
    @State private var searchText = ""
    @State private var showSearchSheet = false
    
    var body: some View {
        ZStack {
            // Map view
            Map {
                MapPolygon(coordinates: lot23)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: lot25)
                    .stroke(.yellow, lineWidth: 1)
                    .foregroundStyle(.yellow.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: lot26)
                    .stroke(.green, lineWidth: 1)
                    .foregroundStyle(.green.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: lot20)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: lot22)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: lot00)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: jacplace)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: owenshall)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: huntermac)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: jessehall)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: backlot)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: quad2)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: handicapO)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: screw12)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
                MapPolygon(coordinates: agri)
                    .stroke(.red, lineWidth: 1)
                    .foregroundStyle(.red.opacity(0.3))
                    .mapOverlayLevel(level: .aboveRoads)
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControlVisibility(.visible)
            .edgesIgnoringSafeArea(.all)
      

        }
       
    }
}

struct SearchSheet: View {
    @Binding var searchText: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search for a parking lot", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 10)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 16)
    }
}

#Preview {
    refMapView()
}

