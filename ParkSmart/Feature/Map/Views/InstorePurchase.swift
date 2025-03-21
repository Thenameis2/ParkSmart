//
//  InstorePurchase.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 3/15/25.
//

import StoreKit
import SwiftUI
import Firebase
import FirebaseFirestore


struct ProductsListView: View {
    
    @EnvironmentObject private var store: TipsStore

    var body: some View {
        
        ForEach(store.items) { item in
            ProductView(item: item)
        }
    }
}

struct ProductView: View {
    
    let item: Product
    var body: some View {
        HStack {
            
            VStack(alignment: .leading,
                   spacing: 3) {
                Text(item.displayName)
                    .font(.system(.title3, design: .rounded).bold())
                Text(item.description)
                    .font(.system(.callout, design: .rounded).weight(.regular))
            }
            
            Spacer()
            
            Button(item.displayPrice) {
                // TODO: Handle purchase
            }
            .tint(.blue)
            .buttonStyle(.bordered)
            .font(.callout.bold())
        }
    }
}


import Foundation

let myTipProducts = [
    "com.ParkSmart.99cent",
    "com.ParkSmart.4.99bill",
    "com.ParkSmart.9.99bill"
]



import Foundation
import StoreKit
import FirebaseAuth

typealias PurchaseResult = Product.PurchaseResult
typealias TransactionLister = Task<Void, Error>

enum TipsError: LocalizedError {
    case failedVerification
    case system(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "User transaction verification failed"
        case .system(let err):
            return err.localizedDescription
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification
    case system(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "User transaction verification failed"
        case .system(let err):
            return err.localizedDescription
        }
    }
}

enum TipsAction: Equatable {
    case successful
    case failed(TipsError)
    
    static func == (lhs: TipsAction, rhs: TipsAction) -> Bool {
            
        switch (lhs, rhs) {
        case (.successful, .successful):
            return true
        case (let .failed(lhsErr), let .failed(rhsErr)):
            return lhsErr.localizedDescription == rhsErr.localizedDescription
        default:
            return false
        }
    }
}

@MainActor
class TipsStore: ObservableObject {
    
    @Published private(set) var items = [Product]()
    @Published private(set) var action: TipsAction? {
        didSet {
            switch action {
            case .failed:
                hasError = true
            default:
                hasError = false
            }
        }
    }
    @Published var hasError = false
    
    private var transactionListener: TransactionLister?
    
    var error: TipsError? {
        switch action {
        case .failed(let err):
            return err
        default:
            return nil
        }
    }
    
    init() {
        
        transactionListener = configureTransactionListener()
        
        Task {
            await retrieveProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }

    func purchase(_ item: Product) async {
        
        do {
            
            let result = try await item.purchase()
            
            try await handlePurchase(from: result)
            
        } catch {
            action = .failed(.system(error))
            print(error)
        }
    }
    
    /// Call to reset the action state within the store
    func reset() {
        action = nil
    }
}

private extension TipsStore {
    
    /// Create a listener for transactions that don't come directly via the purchase function
    func configureTransactionListener() -> TransactionLister {
        
        Task { [weak self] in
            
            do {
               
                for await result in Transaction.updates {
                    
                    let transaction = try self?.checkVerified(result)
                    
                    self?.action = .successful
                    
                    await transaction?.finish()
                }
                
            } catch {
                self?.action = .failed(.system(error))
            }
        }
    }
    
    /// Get all of the products that are on offer
    func retrieveProducts() async {
        do {
            let products = try await Product.products(for: myTipProducts)
            items = products.sorted(by: { $0.price < $1.price })
        } catch {
            action = .failed(.system(error))
            print(error)
        }
    }
    
    // Update the user's points in Firestore
    func updateUserPoints(with points: Double) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        // Fetch the current points, and update them
        userRef.getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            if let document = document, document.exists, let data = document.data(),
               var currentPoints = data["points"] as? Double {
                // Add the new points to the current points
                currentPoints += points
                print("User's current points: \(currentPoints) after adding \(points)")

                // Update the Firestore document with the new points
                userRef.updateData(["points": currentPoints]) { error in
                    if let error = error {
                        print("Error updating points: \(error)")
                    } else {
                        print("User points updated successfully")
                    }
                }
            } else {
                print("User document does not exist or points field is missing")
            }
        }
    }

    
    /// Handle the result when purchasing a product
    // Calculate points based on the product price
    func handlePurchase(from result: PurchaseResult) async throws {
        switch result {
        case .success(let verification):
            print("Purchase was a success, now it's time to verify their purchase")
            
            do {
                let transaction = try checkVerified(verification)
                
                // Retrieve the associated product from the list of available items
                if let purchasedProduct = items.first(where: { $0.id == transaction.productID }) {
                    let price = purchasedProduct.price
                    print("Product price is: \(price)")  // Log price to ensure it's correct
                    
                    let pointsToAdd = calculatePoints(for: price)
                    print("Calculated points: \(pointsToAdd) for price \(price)")  // Log calculated points
                    
                    // Update user points in Firestore
                    await updateUserPoints(with: pointsToAdd)
                } else {
                    print("Purchased product not found in the list")
                }
                
                action = .successful
                await transaction.finish()
                
            } catch {
                print("Error during purchase verification: \(error)")
                action = .failed(.system(error))
            }
            
        case .pending:
            print("The user needs to complete some action on their account before they can complete purchase")
            
        case .userCancelled:
            print("The user hit cancel before their transaction started")
            
        default:
            print("Unknown error")
        }
    }

    // Ensure price matching with cases
    func calculatePoints(for price: Decimal) -> Double {
        print("Calculating points for price: \(price)")  // Log price
        
        let priceValue = NSDecimalNumber(decimal: price).doubleValue
        if abs(priceValue - 4.99) < 0.01 {
            return 60.0  // Allow some tolerance around 4.99
        }
        
        switch priceValue {
        case 0.99:
            return 10.0  // 0.99$ gives 10 points
        case 9.99:
            return 130.0  // 9.99$ gives 130 points
        default:
            print("Unknown price: \(priceValue)")  // Log unexpected prices
            return 0.0  // Default case, just in case we have an unknown price
        }
    }




    
    /// Check if the user is verified with their purchase
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            print("The verification of the user failed")
            throw TipsError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
