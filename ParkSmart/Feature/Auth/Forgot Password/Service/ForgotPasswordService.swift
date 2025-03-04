

import Foundation
import Combine
import Firebase
import FirebaseAuth
protocol ForgotPasswordService {
    func sendPasswordReset(to email: String) async throws
}

final class ForgotPasswordServiceImpl: ForgotPasswordService {
    
    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
}
