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
    @State private var showingAddEventView = false
    let calendarManager = CalendarManager()
    @State private var selectedTab: Tab = .calendar
    
    var isUserAuthenticated: Bool {
        userService.currentUser != nil
    }
    
    func signOut() {
        if userService.signOut() {
            print("Sign out successful")
        } else {
            print("Sign out failed")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
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
                // Ensuring the Add button is above the bottom bar
                .overlay(
                    Group {
                        if selectedTab == .calendar {
                            addButton.padding(.bottom, 50) // Adjust this value based on your bottom bar's height
                        }
                    }, alignment: .bottomTrailing
                )

                if showingSideMenu {
                    SideMenuView(isShowing: $showingSideMenu, signOutAction: signOut)
                        .transition(.move(edge: .leading))
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var addButton: some View {
        Button(action: {
            showingAddEventView.toggle()
        }) {
            Image(systemName: "plus")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
        .sheet(isPresented: $showingAddEventView) {
            let calendarViewModel = CalendarViewModel(currentDate: currentDate, calendarManager: calendarManager)
            let eventViewModel = EventViewModel(calendarManager: calendarManager)
            AddEventView(isPresented: $showingAddEventView, eventViewModel: eventViewModel, selectedDate: calendarViewModel.selectedDate) {
                calendarViewModel.updateDays()
            }
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
                    if userService.signOut() {
                        // Handle additional sign-out logic or UI feedback as needed.
                        print("Sign out successful")
                    }
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
