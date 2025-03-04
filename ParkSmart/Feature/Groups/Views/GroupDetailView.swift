
import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject var vm: GroupsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingInviteMember = false
    @State private var showingAddCar = false
    @State private var showDeleteGroup = false
    @State var selectedCar: Car?
    @State var isDelete: Bool = false
    @State var isError: Bool = false
    @State var errorMessage: String = ""
    
    let group: GroupDetails
    
    var body: some View {
        List {
            Section(header: Text("Vehicles")) {
                if vm.isLoadingCars {
                    ProgressView()
                } else {
                    if !vm.groupCars.isEmpty {
                        ForEach(vm.groupCars.sorted { $0.name < $1.name }, id: \.self) { car in
                            HStack {
                                Text(car.icon)
                                Text(car.name)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCar = car
                            }
                        }
                    } else {
                        Text("There are no vehicles yet")
                    }
                }
            }
            .onAppear {
                vm.fetchGroupCars(groupId: group.id)
            }
            .onReceive(vm.$carListReload) { change in
                if change {
                    vm.fetchGroupCars(groupId: group.id)
                    vm.carListReload = false
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCar = true }) {
                    Image(systemName: "plus")
                }
                .disabled(vm.groupCars.count >= 1) // Disable if there is already one car
            }
        }

        .sheet(isPresented: $showingInviteMember) {
            InviteMemberView(showingSheet: $showingInviteMember, group: group)
                .environmentObject(vm)
        }
        .sheet(isPresented: $showingAddCar) {
            AddCarView(showingSheet: $showingAddCar, group: group)
                .environmentObject(vm)
        }
        .sheet(item: $selectedCar, content: { car in
            EditCarView(isDelete: $isDelete, car: car)
                .environmentObject(vm)
        })
        .alert("Error", isPresented: $vm.hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = vm.state {
                Text(error.localizedDescription)
            } else {
                Text("Something went wrong")
            }
        }
        .alert("Error", isPresented: $isError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func headerView(title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: action) {
                Image(systemName: "plus")
            }
        }
    }
    
    private func deleteCar(at offsets: IndexSet) {
        for index in offsets {
            let carToDelete = vm.groupCars.sorted { $0.name < $1.name }[index]
            vm.deleteCar(groupId: group.id, car: carToDelete)
        }
    }
    
    private func deleteMember(at offsets: IndexSet) {
        
        var isCurrentUser = false
        
        if vm.memberDetails.count > 1 {
            for index in offsets {
                let memberToDelete = vm.memberDetails.sorted { $0.firstName < $1.firstName }[index]
                
                if memberToDelete.userId == sessionService.userDetails?.userId {
                    presentationMode.wrappedValue.dismiss()
                    isCurrentUser = true
                }
                
                vm.deleteMember(userId: memberToDelete.userId, groupId: group.id, isCurrentUser: isCurrentUser)
            }
        } else {
            DispatchQueue.main.async {
                errorMessage = "Cannot leave group with only one member"
                isError = true
            }
        }
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        GroupDetailView(group: GroupDetails.mockGroups.first!)
            .environmentObject(viewModel)
    }
}

