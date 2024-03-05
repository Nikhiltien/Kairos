//
//  User.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseAuthUI
import FirebaseOAuthUI
import FirebaseGoogleAuthUI
import FirebaseEmailAuthUI
import FirebasePhoneAuthUI
import FirebaseFirestore

class AuthStateListener: ObservableObject {
    @Published var isUserAuthenticated: Bool = false
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        self.handle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.isUserAuthenticated = user != nil
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

struct AuthViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var hasCompletedOnboarding: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let authUI = FUIAuth.defaultAuthUI()!
        let providers: [FUIAuthProvider] = [
            FUIEmailAuth(),
            FUIPhoneAuth(authUI: authUI),
            FUIGoogleAuth(authUI: authUI),
            FUIOAuth.appleAuthProvider()
        ]
        authUI.providers = providers
        
        let authViewController = authUI.authViewController()
        return authViewController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    typealias UIViewControllerType = UINavigationController
}

enum UserRole: String {
    case local = "Local"
    case regular = "Regular"
    case premium = "Premium"
}

class User: Identifiable, ObservableObject {
    @Published var id: String
    @Published var account: String?  // Could be Apple ID, phone number, email, etc.
    @Published var userRole: UserRole
    // Consider adding more attributes relevant to your application context.
    
    init(id: String, account: String?, userRole: UserRole) {
        self.id = id
        self.account = account
        self.userRole = userRole
    }
}

class UserSession: ObservableObject {
    @Published var currentUser: User?
    @Published var hasCompletedOnboarding: Bool = false
    
    // Additional logic and methods...
}

class UserService: ObservableObject {
    private let db = Firestore.firestore()

    static let shared = UserService()

    @Published var currentUser: User?

    private init() {}

    func fetchCurrentUser(uid: String, completion: @escaping (Bool) -> Void) {
        let userDoc = db.collection("users").document(uid)
        userDoc.getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let userData = document.data()
                    let userRole = UserRole(rawValue: userData?["role"] as? String ?? UserRole.local.rawValue) ?? .local
                    self?.currentUser = User(id: uid, account: userData?["account"] as? String, userRole: userRole)
                    completion(true)
                } else {
                    // Populate with generic data if Firestore document is missing
                    let email = Auth.auth().currentUser?.email ?? "Not available"
                    self?.currentUser = User(id: uid, account: email, userRole: .local)
                    completion(true)
                }
            }
        }
    }

    func authenticateUser(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Authentication error: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }

            guard let self = self, let authUser = authResult?.user else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            // Initialize currentUser with basic information right after authentication
            let basicUser = User(id: authUser.uid, account: authUser.email, userRole: .local)
            DispatchQueue.main.async {
                self.currentUser = basicUser
                completion(true)
            }
            
            // Optionally fetch more details and update currentUser further
            self.fetchCurrentUser(uid: authUser.uid) { _ in }
        }
    }

    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = nil
            }
            return true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            return false
        }
    }

    func updateUserRole(userId: String, newRole: UserRole, completion: @escaping (Bool) -> Void) {
        let userDoc = db.collection("users").document(userId)
        userDoc.updateData(["role": newRole.rawValue]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating user role: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self.currentUser?.userRole = newRole
                    completion(true)
                }
            }
        }
    }
}
