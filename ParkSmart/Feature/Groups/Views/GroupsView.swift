
import SwiftUI

struct GroupsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @State private var showCreateGroup = false
        
    let mockGroups = GroupDetails.mockGroups
    
    var body: some View {
        
        VStack {
            
            if vm.isLoadingGroups {
                ProgressView()
            } else {
                if vm.groups.isEmpty {
                    Text("You don't have a garage yet")
                } else {
                    
                    List(vm.groups.sorted(by: { $0.name < $1.name }), id: \.id) { group in
                        NavigationLink(destination: GroupDetailView(group: group)
                            .environmentObject(vm)) {
                                HStack {
                                    Image(systemName: "car")
                                        .frame(width: 20, height: 20)
                                        .padding(.trailing, 10)
                                        .foregroundColor(Color(uiColor: .systemBlue))
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(group.name)")
                                            .font(.headline)
                                
                
                                    
                                    }
                                    
                                    Spacer()
                                }
                            }
                        
                    }
                    .refreshable {
                        vm.fetchUserGroups(userId: sessionService.userDetails?.userId ?? "")
                    }
                }
            }
        }
        .onAppear {
            vm.fetchUserGroups(userId: sessionService.userDetails?.userId ?? "")
        }
        .onReceive(vm.$groupChange) { created in
            if created {
                vm.fetchUserGroups(userId: sessionService.userDetails?.userId ?? "")
                vm.groupChange = false
            }
        }
        .alert("Error", isPresented: $vm.hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = vm.state {
                Text(error.localizedDescription)
            } else {
                Text("Something went wrong")
            }
        }
      
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateGroup.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!vm.groups.isEmpty) // Disable button if user already has a group
                .sheet(isPresented: $showCreateGroup, onDismiss: {
                    vm.groupDetails.members = []
                    vm.groupDetails.name = ""
                }) {
                    CreateGroupView(showingSheet: $showCreateGroup)
                        .environmentObject(vm)
                }
            }
        }

        
    }
    
}

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let sessionService = SessionServiceImpl()
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        GroupsView()
            .environmentObject(sessionService)
            .environmentObject(viewModel)
    }
}
