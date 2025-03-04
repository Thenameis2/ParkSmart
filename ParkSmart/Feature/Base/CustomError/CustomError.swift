

import Foundation

enum CustomError: Error, LocalizedError {
    case error(String)
    
    var errorDescription: String? {
           switch self {
           case .error(let message):
               return message
           }
       }
}
