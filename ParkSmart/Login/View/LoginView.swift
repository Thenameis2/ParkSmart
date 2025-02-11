//
//  LoginView.swift
//  ParkSmart
//
//  Created by Mihiretu Jackson on 2/11/25.
//



import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    
    @StateObject private var vm = LoginViewModelImpl(service: LoginServiceImpl())
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo Section
                VStack {
                    Image("Logo", bundle: .main)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(.circle)
                    
                    Text("ParKSmart")
                        .font(.largeTitle)
                        .bold()
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 16) {
                    InputTextFieldView(
                        text: $vm.credentials.email,
                        placeholder: "Email",
                        keyboardType: .emailAddress,
                        sfSymbol: "envelope"
                    )
                    
                    InputPasswordView(
                        password: $vm.credentials.password,
                        placeholder: "Password",
                        sfSymbol: "lock"
                    )
                    
                    Button {
                        showForgotPassword.toggle()
                    } label: {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    ButtonView(title: "Sign In") {
                        vm.login()
                    }
                }
                .padding(.horizontal)
                
                // Divider
                HStack {
                    VStack { Divider() }
                    Text("or")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    VStack { Divider() }
                }
                .padding(.horizontal)
                
                
                // Register Button
                Button {
                    showRegistration.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Text("Sign Up")
                            .foregroundColor(.accentColor)
                    }
                    .font(.footnote)
                }
                .padding(.top)
                
                Spacer()
            }
            .navigationDestination(isPresented: $showRegistration) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                // need to add ForgotPasswordView here when implemented
                Text("Forgot Password View")
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
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
    }
}
