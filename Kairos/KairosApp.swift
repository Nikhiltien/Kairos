import UIKit
import SwiftUI
import FirebaseCore
import FirebaseAuthUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: nil) ?? false
        print("URL Handled: \(handled), URL: \(url)")
        return handled
    }
}

@main
struct KairosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    let plannerViewModel = PlannerViewModel.shared

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
