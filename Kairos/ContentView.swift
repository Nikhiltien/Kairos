//
//  ContentView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject private var userService = UserService.shared
    @State private var currentDate = Date()
    @State private var showingSideMenu = false
    let calendarManager = CalendarManager()
    @State private var selectedTab: Tab = .calendar
    
    // Determine if the user is authenticated
    var isUserAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func signOut() {
        // Sign out logic using FirebaseAuth
        try? Auth.auth().signOut()
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Main view content
                VStack {
                    // Top menu bar
                    HStack {
                        Button(action: { showingSideMenu.toggle() }) {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                                .padding()
                        }

                        Spacer()

                        Button(action: { /* action for settings */ }) {
                            Image(systemName: "ellipsis")
                                .imageScale(.large)
                                .padding()
                        }
                    }

                    // KairosCalendar or the content based on tab selection
                    Group {
                        switch selectedTab {
                        case .social:
                            Text("Social View")
                        case .planner:
                            Text("Planner View")
                        case .calendar:
                            let calendarViewModel = CalendarViewModel(currentDate: currentDate, calendarManager: calendarManager)
                            let eventViewModel = EventViewModel(calendarManager: calendarManager)
                            KairosCalendar(calendarViewModel: calendarViewModel, eventViewModel: eventViewModel)
                        case .chat:
                            Text("Chat View")
                        }
                    }

                    Spacer()

                    // Bottom tab pane
                    HStack {
                        Button("Social") {
                            selectedTab = .social
                        }
                        Spacer()
                        Button("Planner") {
                            selectedTab = .planner
                        }
                        Spacer()
                        Button("Calendar") {
                            selectedTab = .calendar
                        }
                        Spacer()
                        Button("Chat") {
                            selectedTab = .chat
                        }
                    }
                    .padding()
                }

                if showingSideMenu {
                    SideMenuView(isShowing: $showingSideMenu,
                                 signOutAction: signOut)
                        .transition(.move(edge: .leading))
                }
            }
            .navigationBarHidden(true)
        }
    }

    enum Tab {
        case social, planner, calendar, chat
    }
}

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @ObservedObject private var userService = UserService.shared
    let signOutAction: () -> Void
    @State private var activeSheet: ActiveSheet?

    var body: some View {
        VStack(alignment: .leading) {
            Button("Profile") {
                // Action for Profile
            }
            Button("Account") {
                activeSheet = userService.currentUser != nil ? .account : .signInOptions
            }
            Button("Sign Out") {
                signOutAction()
            }
            Button("Privacy") {
                // Action for Privacy
            }
            Button("Premium") {
                // Action for Premium
            }
        }
        .frame(maxWidth: 250)
        .background(Color.gray.opacity(0.5))
        .offset(x: isShowing ? 0 : -250, y: 0)
        .padding(.top, 100)
        .edgesIgnoringSafeArea(.all)
        .sheet(item: $activeSheet) { item in
            switch item {
            case .account:
                AccountView(userService: userService)
            case .signInOptions:
                SignInOptionsView(hasCompletedOnboarding: .constant(false))
            }
        }
    }
}

struct AccountView: View {
    @ObservedObject var userService: UserService

    var body: some View {
        VStack {
            if let user = userService.currentUser {
                Text("Username: \(user.id)")
                Text("Account: \(user.account ?? "Not available")")
                Button("Sign Out") {
                    userService.signOut()
                }
            }
        }
    }
}


struct SignInOptionsView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        NavigationView {
            AuthViewControllerRepresentable(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

enum ActiveSheet: Identifiable {
    case account, signInOptions
    
    var id: Int {
        hashValue
    }
}
