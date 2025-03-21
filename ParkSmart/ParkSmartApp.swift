//
//  ParkSmartApp.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 2/11/25.
//

import SwiftUI
import FirebaseCore
import SwiftUI

import SwiftUI
import FirebaseCore

import SwiftUI
import Firebase
import UserNotifications
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self

        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }

      print(userInfo)

      completionHandler(UIBackgroundFetchResult.newData)
    }
}

import FirebaseFirestore

import FirebaseFirestore

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken, let userId = Auth.auth().currentUser?.uid else {
            print("Failed to get FCM token or user ID")
            return
        }

        let db = Firestore.firestore()
        let tokenRef = db.collection("fcmTokens").document(userId)

        tokenRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching token document: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let existingToken = document.data()?["token"] as? String
                if existingToken == fcmToken {
                    print("FCM token has not changed. No update needed.")
                    return
                }
            }

            // Token has changed or does not exist, update Firestore
            tokenRef.setData(["token": fcmToken], merge: true) { error in
                if let error = error {
                    print("Error saving FCM token: \(error.localizedDescription)")
                } else {
                    print("FCM token successfully updated for user: \(userId)")
                }
            }
        }
    }
}


import SwiftUI
import Firebase
import FirebaseAuth

// Create a NotificationManager to handle navigation logic
import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    @Published var selectedRideRequestId: String?
    @Published var notificationType: String?
    @Published var showRideAcceptedView = false
    
    // Add this property to track and dismiss navigation views
    @Published var dismissAllSheets = false
    
    static let shared = NotificationManager()
    
    func handleNotification(userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let type = userInfo["type"] as? String else { return }
        
        self.notificationType = type
        
        // First dismiss any existing sheets
        self.dismissAllSheets = true
        
        // Use a slight delay to ensure sheets are dismissed before showing new one
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismissAllSheets = false
            
            // Handle different notification types
            switch type {
            case "ride_accepted":
                if let requestId = userInfo["requestId"] as? String {
                    self.selectedRideRequestId = requestId
                    self.showRideAcceptedView = true
                }
            default:
                print("Unknown notification type: \(type)")
            }
        }
    }
}

// Update your AppDelegate to use the NotificationManager
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        print(userInfo)

        // Change this to your preferred presentation option
        completionHandler([[.banner, .badge, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID from userNotificationCenter didReceive: \(messageID)")
        }

        print(userInfo)
        
        // Handle the notification tap
        NotificationManager.shared.handleNotification(userInfo: userInfo)
        
        completionHandler()
    }
}

// Create a view to display when a ride is accepted
struct RideAcceptedView: View {
    let requestId: String
    @EnvironmentObject var sessionService: SessionServiceImpl
    @State private var rideDetails: [String: Any]?
    @State private var driverDetails: [String: Any]?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading ride details...")
            } else if let rideDetails = rideDetails {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your ride has been accepted!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Driver information
                    if let driverDetails = driverDetails {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(driverDetails["displayName"] as? String ?? "Your Driver")
                                    .font(.headline)
                                Text("is on the way")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Ride details
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Pickup: \(rideDetails["pickupLocation"] as? String ?? "Unknown")",
                              systemImage: "mappin.circle.fill")
                        Label("Destination: \(rideDetails["destination"] as? String ?? "Unknown")",
                              systemImage: "mappin.and.ellipse")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button(action: {
                        // Action to contact driver or similar
                    }) {
                        Text("Contact Driver")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                Text("Could not load ride details")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            loadRideDetails()
        }
    }
    
    func loadRideDetails() {
        let db = Firestore.firestore()
        db.collection("rideRequests").document(requestId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading ride details: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let data = snapshot?.data() {
                self.rideDetails = data
                
                // Load driver details if available
                if let driverId = data["driverId"] as? String {
                    db.collection("users").document(driverId).getDocument { snapshot, error in
                        if let driverData = snapshot?.data() {
                            self.driverDetails = driverData
                        }
                        isLoading = false
                    }
                } else {
                    isLoading = false
                }
            } else {
                isLoading = false
            }
        }
    }
}

// Update your main app structure to include the notification routing
@main
struct ParkSmartApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    
    @StateObject var sessionService = SessionServiceImpl()
    @StateObject private var store = TipsStore()
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch sessionService.state {
                case .loggedIn:
                    HomeView()
                        .environmentObject(sessionService)
                        .environmentObject(store)
                        // Remove the sheet from here since we're handling it in HomeView
                case .loggedOut:
                    LoginView()
                        .environmentObject(sessionService)
                }
            }
        }
    }
}
