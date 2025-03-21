//
//  requestcard.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 3/18/25.
//

import SwiftUI



struct RideRequestCard: View {
    let rideRequest: RideRequest
    var onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status and close button
            HStack {
                Label {
                    Text("Ride Request")
                        .font(.headline)
                } icon: {
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(rideRequest.status.capitalized)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Ride details
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
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup")
                            .font(.caption)
                            .foregroundColor(.gray)
//                        Text(rideRequest.pickupLocationName)
//                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destination")
                            .font(.caption)
                            .foregroundColor(.gray)
//                        Text(rideRequest.destinationName)
//                            .font(.subheadline)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Points and ETA
                VStack(alignment: .trailing, spacing: 20) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(rideRequest.pointsOffered)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ETA")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(etaText)
                            .font(.subheadline)
                    }
                }
            }
            
            // Driver info (if matched)
            if rideRequest.status == "accepted" || rideRequest.status == "inProgress" {
                Divider()
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
//                        Text(rideRequest.driverName ?? "Unknown Driver")
//                            .font(.subheadline)
                        Text("Driver")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Call or message driver functionality
                    }) {
                        Image(systemName: "phone.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Cancel button for pending requests
            if rideRequest.status == "pending" {
                Button(action: onCancel) {
                    Text("Cancel Request")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Helper computed properties
    private var statusColor: Color {
        switch rideRequest.status {
        case "pending":
            return .orange
        case "accepted":
            return .green
        case "inProgress":
            return .blue
        case "completed":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private var etaText: String {
        let minutes = Int(rideRequest.estimatedDuration / 60)
        return "\(minutes) min"
    }

}
