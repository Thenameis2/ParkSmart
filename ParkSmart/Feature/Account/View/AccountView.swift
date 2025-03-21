
import SwiftUI


import SwiftUI

struct AccountView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    @StateObject var accountViewModel = AccountViewModelImpl(service: AccountServiceImpl())
    @State var isDeleteAccountAlert = false
    @Environment(\.presentationMode) var presentationMode
    

    var body: some View {
        NavigationStack {
            VStack {
                // Profile Header
                VStack {
                    Image("profile_picture") // Replace with dynamic image loading
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .shadow(radius: 5)
                    
                    Text("\(sessionService.userDetails?.firstName ?? "") \(sessionService.userDetails?.lastName ?? "")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("\(sessionService.userDetails?.userEmail ?? "")")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
                
                List {
                    Section {
                        NavigationLink(destination: WalletView()
                            .environmentObject(sessionService)
                            .environmentObject(TipsStore())
                        ) {
                            Label("My vault", systemImage: "creditcard")
                        }
                        
                        NavigationLink(destination: NotificationsView()) {
                            Label("Plan a Ride", systemImage: "bell")
                        }
                        
                        NavigationLink(destination: NotificationsView()) {
                            Label("Notifications", systemImage: "bell")
                        }
                        
                        NavigationLink(destination: HelpCenterView()) {
                            Label("Help Center", systemImage: "phone.circle")
                        }
                        
                        NavigationLink(destination: PrivacyPolicyView()) {
                            Label("Privacy Policy", systemImage: "lock.shield")
                        }
                        NavigationLink(destination: InviteFriendsView()) {
                            Label("Invite Friends", systemImage: "person.2.fill")
                        }
                        Button(action: {
                            sessionService.logout()
                        }) {
                            HStack {
                                Label("Log Out", systemImage: "arrow.right.circle")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                  
                
                    
                 
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.white.edgesIgnoringSafeArea(.all))
            }
            .background(Color.white)
            .navigationTitle("")
            .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.black)
                                }
                            }
                        }
        }
    }
}

import FirebaseFirestore
import FirebaseAuth
import Combine

class UserViewModel: ObservableObject {
    @Published var points: Double = 0.0
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchUserData()
    }
    
     func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).addSnapshotListener { [weak self] documentSnapshot, error in
            if let error = error {
                print("Error fetching user data: \(error)")
            } else if let document = documentSnapshot, document.exists, let data = document.data() {
                if let userPoints = data["points"] as? Double {
                    self?.points = userPoints
                }
                if let userFirstName = data["firstName"] as? String {
                    self?.firstName = userFirstName
                }
                if let userLastName = data["lastName"] as? String {
                    self?.lastName = userLastName
                }
            }
        }
    }
    
    
}




import SwiftUI
import Combine
import StoreKit

struct WalletView: View {
    @StateObject private var userViewModel = UserViewModel() // Add ViewModel
    @EnvironmentObject private var store: TipsStore
    @State private var showSubscriptionView = false
    @State private var showThanks = false
    @EnvironmentObject var sessionService: SessionServiceImpl  // Add sessionService here

    var body: some View {
        VStack(spacing: 20) {
            Text("Available Points")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("\(userViewModel.points, specifier: "%.2f")") // Bind points here
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
                        Text("\(sessionService.userDetails?.firstName ?? "") \(sessionService.userDetails?.lastName ?? "")")
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
        .navigationBarTitle("My Vault", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Vault")
                    .font(.headline)
            }
        }
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

private extension WalletView {
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


struct TransactionRow: View {
    var title: String
    var amount: Int

    var body: some View {
        HStack {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.black)
                    .font(.headline)
                Text("15 Feb 2025 | 8:10 PM")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("$\(amount)")
                .foregroundColor(.red)
                .fontWeight(.bold)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
    }
}

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
    }
}

struct PaymentMethodsView: View {
    var body: some View {
        Text("Payment Methods View")
            .navigationTitle("Payment Methods")
    }
}

struct NotificationsView: View {
    var body: some View {
        Text("Notifications View")
            .navigationTitle("Notifications")
    }
}

struct HelpCenterView: View {
    var body: some View {
        Text("Help Center View")
            .navigationTitle("Help Center")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy View")
            .navigationTitle("Privacy Policy")
    }
}

struct InviteFriendsView: View {
    var body: some View {
        Text("Invite Friends View")
            .navigationTitle("Invite Friends")
    }
}


struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(accountViewModel: AccountViewModelImpl(service: AccountServiceImpl()))
            .environmentObject(SessionServiceImpl())
    }
}

