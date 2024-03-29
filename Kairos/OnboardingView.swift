//
//  OnboardingView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/26/24.
//

import Foundation
import SwiftUI
import EventKit
import FirebaseOAuthUI

// SignInView using FirebaseUI for authentication
struct SignInView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        AuthViewControllerRepresentable(hasCompletedOnboarding: $hasCompletedOnboarding)
            .onDisappear {
                if Auth.auth().currentUser != nil {
                    hasCompletedOnboarding = true
                }
            }
    }
}

struct CreateAccountView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        AuthViewControllerRepresentable(hasCompletedOnboarding: $hasCompletedOnboarding)
            .onDisappear {
                if Auth.auth().currentUser != nil {
                    hasCompletedOnboarding = true
                }
            }
    }
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Kairos")
                        .font(.custom("Zapfino", size: 64))
                        .foregroundColor(Color.black)

                    Spacer()

                    VStack(spacing: 15) {
                        NavigationLink(destination: LocalModeView(hasCompletedOnboarding: $hasCompletedOnboarding)) {
                            Text("Local")
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 280, height: 50)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .shadow(radius: 5)
                        }

                        NavigationLink(destination: SignInView(hasCompletedOnboarding: $hasCompletedOnboarding)) {
                            Text("Sign In")
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 280, height: 50)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .shadow(radius: 5)
                        }

                        NavigationLink(destination: CreateAccountView(hasCompletedOnboarding: $hasCompletedOnboarding)) {
                            Text("Create Account")
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 280, height: 50)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .shadow(radius: 5)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(15)
                    .shadow(radius: 10)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct LocalModeView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var isShowingAlert = false
    
    private let calendarManager = CalendarManager()
    
    var body: some View {
        CalendarAccessView(hasCompletedOnboarding: $hasCompletedOnboarding)
    }
}

struct CalendarAccessView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var isShowingAlert = false
    private let calendarManager = CalendarManager()

    var body: some View {
        VStack {
            Text("We need access to your calendar to import events.")
                .font(.title2)
                .padding()
                .multilineTextAlignment(.center)

            Button("Grant Access") {
                requestAccessAndLoadEvents()
            }
            Button("Skip") {
                // Allows skipping calendar access.
                hasCompletedOnboarding = true
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Access Denied"), message: Text("You can enable calendar access later in settings."), dismissButton: .default(Text("OK")))
        }
    }

    private func requestAccessAndLoadEvents() {
        calendarManager.requestEventAccess { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.isShowingAlert = true
                }
                // Mark onboarding as complete regardless of permission state.
                self.hasCompletedOnboarding = true
            }
        }
    }
}
