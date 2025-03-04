

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddCarView: View {

    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @Binding var showingSheet: Bool
    
    @State private var carName = ""
    @State private var selectedEmoji: String = ""
    
    let group: GroupDetails

    // Fetch current user ID
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 32) {
                    
                    VStack(spacing: 16) {
                        
                        InputTextFieldView(text: $carName, placeholder: "Vehicle Name", keyboardType: .default, sfSymbol: nil)
                        
                        VehicleEmojiPicker(selectedEmoji: $selectedEmoji)
                        
                    }
                    .padding(.top)
                    
                    ButtonView(title: "Add Vehicle", handler: {
                        if !carName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedEmoji.isEmpty {
                            if let currentUserId = getCurrentUserId() {
                                let newCar = Car(
                                    id: "",
                                    name: carName,
                                    location: GeoPoint(latitude: 0, longitude: 0),
                                    address: "",
                                    groupName: "",
                                    groupId: group.id,
                                    note: "",
                                    icon: selectedEmoji,
                                    currentlyInUse: true,
                                    currentlyUsedById: currentUserId, // Set the current user's ID
                                    currentlyUsedByFullName: "" // You can add logic to fetch the full name if needed
                                )
                                vm.addCarToGroup(groupId: group.id, car: newCar)
                            }
                        }
                        showingSheet = false
                    }, disabled: Binding<Bool>(
                        get: { carName.trimmingCharacters(in: .whitespaces).isEmpty || selectedEmoji.isEmpty },
                        set: { _ in }
                    ))
                    
                }
                .padding(.horizontal, 15)
                .navigationTitle("Add Vehicle")
                .alert("Error", isPresented: $vm.hasError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if case .failed(let error) = vm.state {
                        Text(error.localizedDescription)
                    } else {
                        Text("Something went wrong")
                    }
                }
                .applyClose()
                
            }
        }
    }
}


struct AddCarView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        AddCarView(showingSheet: .constant(true), group: GroupDetails(id: "0", name: "Preview", members: [], cars: []))
            .environmentObject(viewModel)
    }
}
