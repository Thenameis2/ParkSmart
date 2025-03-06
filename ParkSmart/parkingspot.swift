//
//  parkingspot.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 3/5/25.
//

import SwiftUI

import SwiftUI

struct CreateParkingSpotView: View {
    @State private var name: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var available: Bool = true
    @State private var isLoading: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    
    private var navigationManager = NavigationManager()

    var body: some View {
        VStack {
            TextField("Parking Spot Name", text: $name)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
            
            TextField("Latitude", text: $latitude)
                .padding()
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Longitude", text: $longitude)
                .padding()
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Toggle("Available", isOn: $available)
                .padding()
            
            Button(action: {
                // Convert latitude and longitude to Double
                guard let latitudeDouble = Double(latitude),
                      let longitudeDouble = Double(longitude) else {
                    // Handle invalid input
                    showErrorAlert = true
                    return
                }
                
                // Show loading indicator
                isLoading = true
                
                // Call the createParkingSpot method from NavigationManager
                navigationManager.createParkingSpot(name: name, latitude: latitudeDouble, longitude: longitudeDouble, available: available) { success in
                    isLoading = false
                    
                    if success {
                        showSuccessAlert = true
                    } else {
                        showErrorAlert = true
                    }
                }
            }) {
                Text("Create Parking Spot")
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding()
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Parking spot created successfully!"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text("Failed to create parking spot. Please check your input."), dismissButton: .default(Text("OK")))
        }
    }
}

struct CreateParkingSpotView_Previews: PreviewProvider {
    static var previews: some View {
        CreateParkingSpotView()
    }
}


extension NavigationManager {
    // Function to create a parking spot document in Firestore
    func createParkingSpot(name: String, latitude: Double, longitude: Double, available: Bool, completion: @escaping (Bool) -> Void) {
        // Create a new parking spot dictionary
        let parkingSpotData: [String: Any] = [
            "name": name,
            "latitude": latitude,
            "longitude": longitude,
            "available": available
        ]
        
        // Add a new document to the "parkingSpots" collection in Firestore
        db.collection("parkingSpots").addDocument(data: parkingSpotData) { error in
            if let error = error {
                print("Error creating parking spot: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Parking spot created successfully!")
                completion(true)
            }
        }
    }
}
