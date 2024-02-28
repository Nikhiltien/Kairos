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

    // Singleton instance
    static let shared = UserService()

    // Current user instance
    @Published var currentUser: User?

    private init() {}

    // Fetch user data from Firestore and update the currentUser
    func fetchCurrentUser(uid: String, completion: @escaping () -> Void) {
        let userDoc = db.collection("users").document(uid)
        userDoc.getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let userData = document.data()
                    let userRole = UserRole(rawValue: userData?["role"] as? String ?? "Local") ?? .local
                    self?.currentUser = User(id: uid, account: userData?["account"] as? String, userRole: userRole)
                } else {
                    print("User does not exist")
                    // Handle user creation or logging as a local user here if necessary
                }
                completion()
            }
        }
    }

    // Authenticate user and fetch user data upon successful authentication
    func authenticateUser(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let uid = authResult?.user.uid, error == nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            self?.fetchCurrentUser(uid: uid, completion: {
                DispatchQueue.main.async {
                    completion(true)
                }
            })
        }
    }

    // Sign out logic and reset currentUser
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

    // Update user role with completion feedback
    func updateUserRole(userId: String, newRole: UserRole, completion: @escaping (Bool) -> Void) {
        let userDoc = db.collection("users").document(userId)
        userDoc.updateData(["role": newRole.rawValue]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating user role: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self?.currentUser?.userRole = newRole
                    completion(true)
                }
            }
        }
    }
}
