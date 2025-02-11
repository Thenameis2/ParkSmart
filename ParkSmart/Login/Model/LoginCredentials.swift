//
//  LoginCredentials.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 2/11/25.
//

import Foundation

struct LoginCredentials {
    var email: String
    var password: String
}

extension LoginCredentials {
    
    static var new: LoginCredentials {
        LoginCredentials(email: "", password: "")
    }
}
