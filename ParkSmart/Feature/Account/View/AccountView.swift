
import SwiftUI


struct AccountView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var accountViewModel = AccountViewModelImpl(service: AccountServiceImpl())
    
    @State var isDeleteAccountAlert = false
    
    private let pastboard = UIPasteboard.general
    
    var body: some View {
        
        NavigationStack {
            
            VStack(alignment: .leading, spacing: 20) {
                
                if accountViewModel.isLoadingDeleteAccount {
                    VStack(alignment: .center) {
                        ProgressView()
                        Text("Deleting account please wait..")
                            .bold()
                    }
                } else {
                    
                    VStack(alignment: .leading, spacing: 25) {
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Name:")
                                    .font(.headline)
                                
                                Text("\(sessionService.userDetails?.firstName ?? "") \(sessionService.userDetails?.lastName ?? "")")
                                    .font(.title3)
                            }
                      
                            
                            Divider()
                            
                            HStack {
                                
                                Text("Email:")
                                    .font(.headline)
                                
                                Text("\(sessionService.userDetails?.userEmail ?? "")")
                                
                            }
                            
                  
                        }

                  
                        
                    }
                    
                    Divider()
                    
                    ButtonView(title: "Sign Out") {
                        sessionService.logout()
                    }
                    
                    ButtonView(title: "Delete Account", background: .red) {
                        isDeleteAccountAlert = true
                    }
                    .disabled(sessionService.userDetails?.userId.isEmpty ?? true)
                    .alert("Delete Account", isPresented: $isDeleteAccountAlert) {
                        Button("Confirm", action: {
                            Task {
                                if let userId = sessionService.userDetails?.userId {
                                    if await accountViewModel.deleteAccount(userId: userId) {
                                        sessionService.logout()
                                    }
                                }
                            }
                        })
                        Button("Cancel", role: .cancel) {
                            isDeleteAccountAlert = false
                        }
                    } message: {
                        Text("Confirm if you intend to delete your account along with all its associated data.")
                    }
                }

            }
            .onAppear {
                accountViewModel.isLoading = true

                if let userEmail = sessionService.userDetails?.userEmail {
                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                }
            }
            .onChange(of: sessionService.userDetails) { newUserDetails in
                accountViewModel.isLoading = true

                if let userEmail = newUserDetails?.userEmail {
                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                }
            }
            .padding([.horizontal, .bottom], 16)
            .navigationTitle("Profile")
            .alert("Error", isPresented: $accountViewModel.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = accountViewModel.state {
                    Text(error.localizedDescription)
                } else {
                    Text("Something went wrong")
                }
            }
        }
    }
    
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(accountViewModel: AccountViewModelImpl(service: AccountServiceImpl()))
            .environmentObject(SessionServiceImpl())
    }
}

