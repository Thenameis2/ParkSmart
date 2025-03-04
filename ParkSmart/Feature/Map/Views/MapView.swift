

import SwiftUI
import MapKit

import SwiftUI
import MapKit

import SwiftUI
import MapKit

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var groupsViewModel: GroupsViewModelImpl
    
    @State private var showNavigationMenu = false
    @State private var showGroupsView = false
    @State private var showAccountView = false
    @State private var showLocationUpdateAlert = false
    @State private var showAccountMenu = false  // New state for account menu
    
    private var region: Binding<MKCoordinateRegion> {
        Binding {
            mapViewModel.region
        } set: { region in
            DispatchQueue.main.async {
                mapViewModel.region = region
            }
        }
    }
    
    private var isUserUsingCar: Bool {
        guard let userId = sessionService.userDetails?.userId else { return false }
        return carsViewModel.cars.contains { car in
            car.currentlyInUse && car.currentlyUsedById == userId
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: carsViewModel.cars.filter { $0.location.latitude != 0 && $0.location.longitude != 0 }) { car in
                
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: car.location.latitude, longitude: car.location.longitude)) {
                    VStack {
                        Text(car.icon)
                        Text(car.name)
                            .font(.system(.caption))
                            .foregroundStyle(.gray)
                        
                    
                    }
                    .onTapGesture {
                        Task {
                            await carsViewModel.selectCar(car)
                        }
                    }
                }
            }
            .gesture(DragGesture().onChanged({ _ in
                mapViewModel.isCurrentLocationClicked = false
            }))
            .ignoresSafeArea(edges: .top)
            .onAppear {
                mapViewModel.getCurrentLocation()
                if let userId = sessionService.userDetails?.userId {
                    Task {
                        await carsViewModel.fetchUserCars(userId: userId)
                    }
                }
            }
            
            
            
            // Menu and Profile buttons
            HStack {
                // Profile Button
                Button {
                    showAccountMenu = true
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.leading, 10)
                        .background(Color.blue, in: Circle())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Menu Button
                Button {
                    if isUserUsingCar {
                        showLocationUpdateAlert.toggle()
                    } else {
                        showNavigationMenu.toggle()
                    }
                } label: {
                    Image(systemName: showNavigationMenu ? "parkingsign.circle" : "parkingsign.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .padding(.trailing, 5)
            }
            .padding(.top, 10)
            
            // Account menu sheet
            .sheet(isPresented: $showAccountMenu) {
                NavigationStack {
                    List {
                     
                       
                        HStack {
                            Button {
                                showGroupsView = true
                            } label: {
                                Label("Garage", systemImage: "person.3")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .navigationDestination(isPresented: $showGroupsView) {
                            GroupsView().environmentObject(groupsViewModel)
                        }
                        
                        HStack {
                            Button {
                                showAccountView = true
                            } label: {
                                Label("Profile", systemImage: "person.crop.circle")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Button {
                                if let url = URL(string: "mailto:nir.neuman@icloud.com?subject=Help and Feedback TagAuto"),
                                   UIApplication.shared.canOpenURL(url)
                                {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            } label: {
                                Label("Help & Feedback", systemImage: "questionmark.circle")
                            }
                        }
                        .navigationDestination(isPresented: $showAccountView) {
                            AccountView()
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("Account")
                                .font(.headline)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showAccountMenu = false
                            } label: {
                                Text("Done").bold()
                            }
                        }
                    }
                    .toolbarTitleDisplayMode(.inline) // Makes title align left
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }

            
            // Navigation menu sheet
            .sheet(isPresented: $showNavigationMenu) {
                NavigationStack {
                    GroupsView().environmentObject(groupsViewModel)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            
            // Location update sheet
            .sheet(isPresented: $showLocationUpdateAlert, onDismiss: {
                mapViewModel.pickedLocation = nil
                mapViewModel.pickedPlaceMark = nil
                mapViewModel.searchText = ""
                mapViewModel.mapView.removeAnnotations(mapViewModel.mapView.annotations)
            }) {
                if let userCar = carsViewModel.cars.first(where: { car in
                    guard let userId = sessionService.userDetails?.userId else { return false }
                    return car.currentlyInUse && car.currentlyUsedById == userId
                }) {
                    SearchView(showingSheet: $showLocationUpdateAlert, car: userCar)
                        .environmentObject(mapViewModel)
                        .environmentObject(carsViewModel)
                        .environmentObject(sessionService)
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .onChange(of: carsViewModel.selectedCar) { selectedCar in
            guard let coordinate = selectedCar?.location else { return }
            if coordinate.latitude != 0 && coordinate.longitude != 0 {
                let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: coordinate.latitude - Constants.defaultSubtractionForMapAnnotation,
                        longitude: coordinate.longitude
                    ),
                    span: MapDetails.defaultSpan
                )
                DispatchQueue.main.async {
                    mapViewModel.region = region
                }
            }
            mapViewModel.isCurrentLocationClicked = false
        }
        .onChange(of: carsViewModel.currentLocationFocus) { newLocation in
            if let location = newLocation {
                let centeredLocation = CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude - Constants.defaultSubtractionForMapAnnotation,
                    longitude: location.coordinate.longitude
                )
                mapViewModel.region = MKCoordinateRegion(
                    center: centeredLocation,
                    span: MapDetails.defaultSpan
                )
            }
        }
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
