//
//  KairosApp.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/25/24.
//

import SwiftUI
import SwiftData

@main
struct KairosApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()  // Main content view after onboarding
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}
