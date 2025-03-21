//
//  shopview.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 3/15/25.
//

import SwiftUI
import StoreKit

import SwiftUI

struct ShopView: View {
    @Environment(\.presentationMode) var presentationMode  // Allows dismissing the view

    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to the Shop")
                    .font(.largeTitle)
                    .padding()

                Spacer()

                Button("Close") {
                    presentationMode.wrappedValue.dismiss()  // Close the shop view
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}





