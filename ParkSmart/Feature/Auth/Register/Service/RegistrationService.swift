

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

enum RegistrationKeys: String {
    case firstName
    case lastName
    case userEmail
    case points  // Added points case
}


protocol RegistrationService {
    func register(with details: RegistrationDetails) -> AnyPublisher<Void, Error>
    func saveUserFcmToken(_ userId: String)
}

final class RegistrationServiceImpl: RegistrationService {
    
    func register(with details: RegistrationDetails) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                Auth.auth()
                    .createUser(withEmail: details.email.lowercased(), password: details.password) { res, err in
                        
                        if let err = err {
                            promise(.failure(err))
                        } else {
                            
                            if let uid = res?.user.uid {
                                
                                let values = [
                                    RegistrationKeys.firstName.rawValue: details.firstName,
                                    RegistrationKeys.lastName.rawValue: details.lastName,
                                    RegistrationKeys.userEmail.rawValue: details.email.lowercased(),
                                    RegistrationKeys.points.rawValue: 0 // Use RegistrationKeys for points
                                ] as [String: Any]
                                
                                let db = Firestore.firestore()
                                db.collection("users").document(uid).setData(values) { err in
                                    
                                    if let err = err {
                                        promise(.failure(err))
                                    } else {
                                        promise(.success(()))
//                                        self.saveUserFcmToken(uid)
                                    }
                                }
                                
                            } else {
                                promise(.failure(CustomError.error("Invalid User Id")))
                            }
                        }
                    }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    /// Save the user's device FCM token for sending the device notifications
    /// - Parameter userId: The user's id
    func saveUserFcmToken(_ userId: String) {
        // Get the FCM token form user defaults
        guard let fcmToken = UserDefaults.standard.value(forKey: Constants.FCM_TOKEN) else {
            return
        }
        
        let values = [Constants.FCM_TOKEN: fcmToken] as [String: Any]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(values)
        
    }
}
