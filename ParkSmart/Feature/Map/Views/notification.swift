//
//  notification.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 3/18/25.
//
//
//import SwiftUI
//import FirebaseFirestore
//import CoreLocation
//
//class NotificationCoordinator: ObservableObject {
//    @Published var activeRideId: String?
//    @Published var isShowingRideDetails = false
//    
//    init() {
//        // Subscribe to the notification
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleRideAccepted),
//            name: .rideAccepted,
//            object: nil
//        )
//    }
//    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//    
//    @objc private func handleRideAccepted(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let requestId = userInfo["requestId"] as? String else {
//            return
//        }
//        
//        // Set the active ride ID
//        self.activeRideId = requestId
//        
//        // Show ride details screen
//        DispatchQueue.main.async {
//            self.isShowingRideDetails = true
//        }
//    }
//    
//    // Function to fetch the accepted ride
//    func fetchAcceptedRide(requestId: String, completion: @escaping (Result<Ride, Error>) -> Void) {
//        let db = Firestore.firestore()
//        
//        // First, check the rides collection where the requestId matches
//        db.collection("rides")
//            .whereField("requestId", isEqualTo: requestId)
//            .getDocuments { (snapshot, error) in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                guard let documents = snapshot?.documents, !documents.isEmpty else {
//                    completion(.failure(NSError(domain: "RideNotFound", code: 404, userInfo: nil)))
//                    return
//                }
//                
//                // Parse the first ride found
//                if let rideData = documents.first?.data() {
//                    do {
//                        // Create a Ride object from the data
//                        let ride = Ride(
//                            id: documents.first!.documentID,
//                            requestId: rideData["requestId"] as? String ?? "",
//                            riderId: rideData["riderId"] as? String ?? "",
//                            driverId: rideData["driverId"] as? String ?? "",
//                            pickupLocation: rideData["pickupLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
//                            destination: rideData["destination"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
//                            status: rideData["status"] as? String ?? "",
//                            pointsOffered: rideData["pointsOffered"] as? Int ?? 0,
//                            estimatedDistance: rideData["estimatedDistance"] as? Double ?? 0,
//                            estimatedDuration: rideData["estimatedDuration"] as? Double ?? 0,
//                            createdAt: (rideData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
//                        )
//                        completion(.success(ride))
//                    } catch {
//                        completion(.failure(error))
//                    }
//                } else {
//                    completion(.failure(NSError(domain: "InvalidRideData", code: 400, userInfo: nil)))
//                }
//            }
//    }
//}
//
//
//// Define a Ride model to match your Firestore data structure
//struct Ride: Identifiable {
//    let id: String
//    let requestId: String
//    let riderId: String
//    let driverId: String
//    let pickupLocation: GeoPoint
//    let destination: GeoPoint
//    let status: String
//    let pointsOffered: Int
//    let estimatedDistance: Double
//    let estimatedDuration: Double
//    let createdAt: Date
//    
//    // Computed properties for location coordinates
//    var pickupCoordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: pickupLocation.latitude, longitude: pickupLocation.longitude)
//    }
//    
//    var destinationCoordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude)
//    }
//}
