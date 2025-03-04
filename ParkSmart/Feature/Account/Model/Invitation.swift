import Foundation

struct Invitation: Hashable, Identifiable {
    let id: String
    let email: String
    let groupId: String
    let groupName: String
}
