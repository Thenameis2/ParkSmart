import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import MapKit

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import MapKit

struct FindARideView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tipsStore: TipsStore
    @StateObject private var locationManager = LocationManager()
    @State private var pointsOffered: Double = 20.0
    @State private var showingConfirmation = false
    @State private var isCreatingRequest = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var destinationName: String = ""
    @State private var pickupName: String = "Current Location"
    @State private var destinationAddress: String = "Loading address..."
    @State private var pickupAddress: String = "Current Location"
    
    // Access the user view model to check points
    @StateObject private var userViewModel = UserViewModel()
    
    // Address manager to fetch address strings
    private let addressManager = AddressManager()
    
    // These would be passed from the previous view
    var destination: CLLocationCoordinate2D?
    var route: MKRoute?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    
                    Text("Find a Ride")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                        .frame(width: 44) // For visual balance
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Route info section
                        routeInfoSection
                        
                        // Points offering section
                        pointsSelectionSection
                        
                        // Available points
                        availablePointsSection
                        
                        Spacer(minLength: 20)
                        
                        // Create request button
                        createRequestButton
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred"), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingConfirmation) {
                requestConfirmationView
            }
            .onAppear {
                // If we have route information, extract the destination name
                if let lastStep = route?.steps.last {
                    destinationName = lastStep.notice ?? "Destination"
                }
                
                // Fetch the address for the destination
                if let destination = destination {
                    addressManager.fetchAddress(for: destination) { address in
                        if let address = address {
                            self.destinationAddress = address
                        }
                    }
                }
                
                // Fetch the address for the current location
                if let currentLocation = locationManager.location?.coordinate {
                    addressManager.fetchAddress(for: currentLocation) { address in
                        if let address = address {
                            self.pickupAddress = address
                        }
                    }
                }
            }
        }
    }
    
    private var routeInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ride Details")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(alignment: .top) {
                VStack(alignment: .center) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 30)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                }
                .padding(.top, 5)
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Pickup")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(pickupAddress)
                            .font(.body)
                            .lineLimit(1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Destination")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(destinationAddress)
                            .font(.body)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
            }
            
            if let route = route {
                HStack {
                    Label(
                        title: { Text("\(Int(route.expectedTravelTime / 60)) min") },
                        icon: { Image(systemName: "clock") }
                    )
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Label(
                        title: { Text(String(format: "%.1f mi", route.distance / 1609.34)) },
                        icon: { Image(systemName: "map") }
                    )
                    .foregroundColor(.gray)
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var pointsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Points to Offer")
                .font(.headline)
            
            Text("Higher points may attract drivers faster")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Points slider
            VStack {
                Slider(value: $pointsOffered, in: 20...100, step: 5)
                    .accentColor(.blue)
                
                HStack {
                    Text("20")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(Int(pointsOffered))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(Int(min(userViewModel.points, 100)))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    
    private var availablePointsSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Available Points")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(Int(userViewModel.points))")
                    .font(.headline)
            }
            
            Spacer()
            
            Button(action: {
                // Navigate to add points screen
                // This would be implemented separately
            }) {
                Text("Add Points")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var createRequestButton: some View {
        Button(action: {
            if userViewModel.points >= pointsOffered {
                showingConfirmation = true
            } else {
                errorMessage = "You don't have enough points."
                showError = true
            }
        }) {
            HStack {
                if isCreatingRequest {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Find a Driver")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isCreatingRequest)
        }
    }
    
    private var requestConfirmationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.top, 30)
            
            Text("Confirm Ride Request")
                .font(.headline)
            
            Text("You're about to offer \(Int(pointsOffered)) points for this ride.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: {
                    showingConfirmation = false
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    createRideRequest()
                }) {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .padding()
    }
    
    private func createRideRequest() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in to request a ride."
            showError = true
            return
        }
        
        guard let userLocation = locationManager.location,
              let destination = destination else {
            errorMessage = "Unable to get location information."
            showError = true
            return
        }
        
        isCreatingRequest = true
        
        // Create the ride request data
        let db = Firestore.firestore()
        let requestData: [String: Any] = [
            "userId": userId,
            "pickupLocation": GeoPoint(latitude: userLocation.coordinate.latitude,
                                     longitude: userLocation.coordinate.longitude),
            "destination": GeoPoint(latitude: destination.latitude,
                                  longitude: destination.longitude),
            "pickupAddress": pickupAddress,
            "destinationAddress": destinationAddress,
            "timestamp": Timestamp(date: Date()),
            "status": "pending",
            "pointsOffered": Int(pointsOffered),
            "riderName": "\(userViewModel.firstName) \(userViewModel.lastName)",
            "estimatedDistance": route?.distance ?? 0,
            "estimatedDuration": route?.expectedTravelTime ?? 0
        ]
        
        // Save to Firestore
        db.collection("rideRequests").addDocument(data: requestData) { error in
            isCreatingRequest = false
            
            if let error = error {
                errorMessage = "Failed to create ride request: \(error.localizedDescription)"
                showError = true
                showingConfirmation = false
            } else {
                // Deduct points from user
                self.deductPoints(Int(pointsOffered))
                
                // Close the confirmation sheet
                showingConfirmation = false
                
                // Return to the previous view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func deductPoints(_ amount: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                userDocument = try transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldPoints = userDocument.data()?["points"] as? Double else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve user points"])
                errorPointer?.pointee = error
                return nil
            }
            
            let newPoints = oldPoints - Double(amount)
            
            transaction.updateData(["points": newPoints], forDocument: userRef)
            return newPoints
        }) { (result, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct FindARideView_Previews: PreviewProvider {
    static var previews: some View {
        FindARideView()
            .environmentObject(TipsStore())
    }
}



import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import MapKit

struct RideRequest: Identifiable {
    let id: String
    let userId: String
    let riderName: String
    let pickupLocation: GeoPoint
    let destination: GeoPoint
    let timestamp: Date
    let status: String
    let pointsOffered: Int
    let estimatedDistance: Double
    let estimatedDuration: Double
    
    var pickupCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: pickupLocation.latitude, longitude: pickupLocation.longitude)
    }
    
    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude)
    }
    
    var pickupAddress: String?
    var destinationAddress: String?
}

import CoreLocation

class AddressManager {
    func fetchAddress(for coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                completion(nil)
                return
            }
            
            // Create a formatted address
            var addressComponents: [String] = []
            
            // Add street address
            if let thoroughfare = placemark.thoroughfare {
                let streetAddress = placemark.subThoroughfare != nil ? "\(placemark.subThoroughfare!) \(thoroughfare)" : thoroughfare
                addressComponents.append(streetAddress)
            } else if let name = placemark.name {
                addressComponents.append(name)
            }
            
            // Add locality (city)
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            
            // Add administrative area (state) and postal code
            if let administrativeArea = placemark.administrativeArea {
                let postalComponent = placemark.postalCode != nil ? "\(administrativeArea) \(placemark.postalCode!)" : administrativeArea
                addressComponents.append(postalComponent)
            }
            
            let formattedAddress = addressComponents.joined(separator: ", ")
            completion(formattedAddress.isEmpty ? nil : formattedAddress)
        }
    }
}



struct DriverRideRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var rideRequests: [RideRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var selectedRequest: RideRequest? = nil
    @State private var showingRequestDetail = false
    @State private var maxDistance: Double = 10.0 // miles
    @State private var sortOption = "distance" // "distance", "points", "time"
    
    let addressManager = AddressManager() // Add this to fetch addresses
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
//                    // Header
//                    HStack {
//                        Text("Available Ride Requests")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                    }
//                    .padding(.horizontal)
//                    .background(Color(.systemBackground))
//                    
//                    // Filter options (Make sure it's inside the ScrollView)
//                    filterOptionsView
//                    
                    // Content
                    if isLoading {
                        ProgressView("Loading ride requests...")
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if rideRequests.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No ride requests available")
                                .font(.headline)
                            Text("Pull down to refresh or check back later")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(rideRequests) { request in
                                rideRequestCard(request)
                                    .onTapGesture {
                                        selectedRequest = request
                                        showingRequestDetail = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
                .padding(.bottom, 20) // Extra space for scrolling
            }
            .refreshable { loadRideRequests() }
            .navigationBarHidden(true)
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred"), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingRequestDetail) {
                if let request = selectedRequest {
                    RideRequestDetailView(request: request)
                }
            }
        
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarHidden(true)
            .onAppear {
                // Request location permission when view appears
                locationManager.requestLocationAuthorization()
                // Give location services a moment to initialize before loading requests
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    loadRideRequests()
                }
            }
        }
    }
    
//    private var filterOptionsView: some View {
//        VStack(spacing: 10) {
//            HStack {
//                Text("Filter & Sort")
//                    .font(.headline)
//                Spacer()
//            }
//            .padding(.horizontal)
//            .padding(.top)
//            
//            HStack {
//                Text("Max Distance: \(Int(maxDistance)) miles")
//                    .font(.subheadline)
//                Spacer()
//            }
//            .padding(.horizontal)
//            
//            Slider(value: $maxDistance, in: 1...50, step: 1)
//                .accentColor(.blue)
//                .padding(.horizontal)
//                .onChange(of: maxDistance) { _ in
//                    loadRideRequests()
//                }
//            
//            HStack(spacing: 10) {
//                sortButton("Distance", option: "distance")
//                sortButton("Points", option: "points")
//                sortButton("Time", option: "time")
//            }
//            .padding(.horizontal)
//            .padding(.bottom)
//        }
//        .background(Color(.secondarySystemBackground))
//    }
    
    private func sortButton(_ title: String, option: String) -> some View {
        Button(action: {
            sortOption = option
            loadRideRequests()
        }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(sortOption == option ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(sortOption == option ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(20)
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
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // Rider name
                    Text("Rider: \(request.riderName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // Route details
            HStack(alignment: .top) {
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 64)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Pickup location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                        Text("Destination")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                
                VStack(alignment: .trailing, spacing: 16) {
             
                    
                    if let userLocation = locationManager.location {
                        let distance = calculateDistance(from: userLocation.coordinate, to: request.pickupCoordinate)
                        Text(String(format: "%.1f mi away", distance))
                            .font(.subheadline)
                           
                    }
                }
            }
            
            // Rider name
//            Text("Rider: \(request.riderName)")
//                .font(.subheadline)
//                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
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
                    return
                }
                
                // Parse ride requests
                var requests = documents.compactMap { document -> RideRequest? in
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
                    
                    let pickupCoordinate = CLLocationCoordinate2D(
                        latitude: pickupLocation.latitude,
                        longitude: pickupLocation.longitude
                    )
                    
                    // Filter by distance
                    let distance = calculateDistance(from: userLocation.coordinate, to: pickupCoordinate)
                    if distance > maxDistance {
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
                
                // Sort the requests
                switch sortOption {
                case "distance":
                    requests.sort { (req1, req2) -> Bool in
                        let dist1 = calculateDistance(from: userLocation.coordinate, to: req1.pickupCoordinate)
                        let dist2 = calculateDistance(from: userLocation.coordinate, to: req2.pickupCoordinate)
                        return dist1 < dist2
                    }
                case "points":
                    requests.sort { $0.pointsOffered > $1.pointsOffered }
                case "time":
                    requests.sort { $0.timestamp > $1.timestamp }
                default:
                    break
                }
                
                self.rideRequests = requests
                
                // Fetch addresses for all requests
                for index in requests.indices {
                    self.fetchAddressForRequest(at: index)
                }
            }
    }
    
    private func fetchAddressForRequest(at index: Int) {
        guard index < rideRequests.count else { return }
        
        // Fetch pickup address
        addressManager.fetchAddress(for: rideRequests[index].pickupCoordinate) { address in
            DispatchQueue.main.async {
                if index < self.rideRequests.count {
                    self.rideRequests[index].pickupAddress = address ?? "Unknown Address"
                }
            }
        }
        
        // Fetch destination address
        addressManager.fetchAddress(for: rideRequests[index].destinationCoordinate) { address in
            DispatchQueue.main.async {
                if index < self.rideRequests.count {
                    self.rideRequests[index].destinationAddress = address ?? "Unknown Address"
                }
            }
        }
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

struct RideRequestDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var region = MKCoordinateRegion()
    @State private var route: MKRoute?
    @State private var isAcceptingRide = false
    @State private var showingConfirmation = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    
    var userSelectedDestination: CLLocationCoordinate2D?
    @StateObject private var locationManager = LocationManager()
    
    let request: RideRequest
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    
                    Text("Ride Details")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                        .frame(width: 44)
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Map view
//                        mapView
//                            .frame(height: 200)
//                            .cornerRadius(12)
//                            .padding(.horizontal)
                        
                        // Points offered
                        HStack {
                            Text("\(request.pointsOffered) points")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Estimated Earnings")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("$\(String(format: "%.2f", Double(request.pointsOffered) * 0.1))")
                                    .font(.headline)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Ride info
                        rideInfoSection
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        // Rider info
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Rider Information")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading) {
                                    Text(request.riderName)
                                        .font(.body)
                                    
                                    // Rating would come from user profile
                                    HStack {
                                        ForEach(0..<5) { i in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                        Text("(5.0)")
                                                                                    .font(.caption)
                                                                                    .foregroundColor(.gray)
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                .padding()
                                                                .background(Color(.secondarySystemBackground))
                                                                .cornerRadius(12)
                                                                .padding(.horizontal)
                                                                
                                                                // Accept button
                                                                Button(action: {
                                                                    showingConfirmation = true
                                                                }) {
                                                                    if isAcceptingRide {
                                                                        ProgressView()
                                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                    } else {
                                                                        Text("Accept Rider")
                                                                            .fontWeight(.bold)
                                                                    }
                                                                }
                                                                .frame(maxWidth: .infinity)
                                                                .padding()
                                                                .background(Color.blue)
                                                                .foregroundColor(.white)
                                                                .cornerRadius(12)
                                                                .padding(.horizontal)
                                                                .disabled(isAcceptingRide)
                                                                
                                                                Spacer()
                                                            }
                                                            .padding(.vertical)
                                                        }
                                                    }
                                                    .navigationBarHidden(true)
                                                    .alert(isPresented: $showingConfirmation) {
                                                        Alert(
                                                            title: Text("Accept Rider"),
                                                            message: Text("Are you sure you want to accept this ride request?"),
                                                            primaryButton: .default(Text("Yes")) {
                                                                acceptRideRequest()
                                                            },
                                                            secondaryButton: .cancel()
                                                        )
                                                    }
                                                    .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                                                        Button("OK", role: .cancel) {}
                                                    } message: { message in
                                                        Text(message)
                                                    }
                                                    .onAppear {
                                                        setupMap()
                                                    }
                                                }
                                            }
                                            

                                            
                                            private var rideInfoSection: some View {
                                                VStack(alignment: .leading, spacing: 16) {
                                                    Text("Ride Information")
                                                        .font(.headline)
                                                    
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
                                                    
                                                    Divider()
                                                    
                                                    HStack {
                                                        tripInfoItem(icon: "arrow.left.and.right", title: "Distance", value: String(format: "%.1f mi", request.estimatedDistance / 1609.34))
                                                        
                                                        Divider()
                                                            .frame(height: 40)
                                                        
                                                        tripInfoItem(icon: "clock", title: "Duration", value: "\(Int(request.estimatedDuration / 60)) min")
                                                       
                                                    }
                                                }
                                            }
                                            
                                            private func tripInfoItem(icon: String, title: String, value: String) -> some View {
                                                VStack(spacing: 5) {
                                                    Image(systemName: icon)
                                                        .foregroundColor(.gray)
                                                    Text(title)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                    Text(value)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            
                                            private func setupMap() {
                                                // Center the map to show both pickup and destination
                                                let centerLatitude = (request.pickupCoordinate.latitude + request.destinationCoordinate.latitude) / 2
                                                let centerLongitude = (request.pickupCoordinate.longitude + request.destinationCoordinate.longitude) / 2
                                                
                                                // Calculate the span to encompass both points with some padding
                                                let latDelta = abs(request.pickupCoordinate.latitude - request.destinationCoordinate.latitude) * 1.5
                                                let longDelta = abs(request.pickupCoordinate.longitude - request.destinationCoordinate.longitude) * 1.5
                                                
                                                region = MKCoordinateRegion(
                                                    center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                                                    span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01), longitudeDelta: max(longDelta, 0.01))
                                                )
                                                
                                                // Request directions
//                                                calculateRoute()
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
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceInMeters = fromLocation.distance(from: toLocation)
        return distanceInMeters / 1609.34 // Convert to miles
    }
                                            
                                            private func acceptRideRequest() {
                                                isAcceptingRide = true
                                                
                                                guard let currentUserId = Auth.auth().currentUser?.uid else {
                                                    errorMessage = "You need to be signed in to accept rides"
                                                    showError = true
                                                    isAcceptingRide = false
                                                    return
                                                }
                                                
                                                let db = Firestore.firestore()
                                                
                                                // Update the ride request status
                                                db.collection("rideRequests").document(request.id).updateData([
                                                    "status": "accepted",
                                                    "driverId": currentUserId,
                                                    "acceptedAt": Timestamp(date: Date())
                                                ]) { error in
                                                    isAcceptingRide = false
                                                    
                                                    if let error = error {
                                                        errorMessage = "Failed to accept ride: \(error.localizedDescription)"
                                                        showError = true
                                                        return
                                                    }
                                                    
                                                    // Create a ride record
                                                    let rideData: [String: Any] = [
                                                        "requestId": request.id,
                                                        "riderId": request.userId,
                                                        "driverId": currentUserId,
                                                        "pickupLocation": request.pickupLocation,
                                                        "destination": request.destination,
                                                        "status": "driverEnRoute",
                                                        "pointsOffered": request.pointsOffered,
                                                        "estimatedDistance": request.estimatedDistance,
                                                        "estimatedDuration": request.estimatedDuration,
                                                        "createdAt": Timestamp(date: Date())
                                                    ]
                                                    
                                                    db.collection("rides").addDocument(data: rideData) { error in
                                                        if let error = error {
                                                            errorMessage = "Failed to create ride: \(error.localizedDescription)"
                                                            showError = true
                                                            return
                                                        }
                                                        
                                                        // Navigation to the active ride screen would go here
                                                        // For now, just dismiss this view
                                                        dismiss()
                                                    }
                                                }
                                            }
                                        }

                                        struct MapAnnotation: Identifiable {
                                            let id = UUID()
                                            let coordinate: CLLocationCoordinate2D
                                            let title: String
                                        }

                                

                                        // Preview for SwiftUI Canvas
                                        struct DriverRideRequestsView_Previews: PreviewProvider {
                                            static var previews: some View {
                                                DriverRideRequestsView()
                                            }
                                        }
