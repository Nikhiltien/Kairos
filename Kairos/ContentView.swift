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
                    // Navigation bar section
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

                    // Main content based on selected tab
                    Group {
                        switch selectedTab {
                        case .social:
                            Text("Social View")
                        case .planner:
                            PlannerView(
                                addAction: { _ in print("Add Action") },
                                editAction: { _ in print("Edit Action") },
                                deleteAction: { _ in print("Delete Action") }
                            )
                        case .calendar:
                            calendarViewSection
                        case .chat:
                            Text("Chat View")
                        }
                    }

                    Spacer()

                    CustomTabBar(selectedTab: $selectedTab)
                }

                if showingSideMenu {
                    SideMenuView(isShowing: $showingSideMenu, signOutAction: signOut)
                        .transition(.move(edge: .leading))
                }

                // Add button for the calendar view
                if selectedTab == .calendar {
                    VStack {
                        Spacer() // Pushes the content to the bottom
                        HStack {
                            Spacer() // Pushes the content to the right
                            addButton
                        }
                    }
                    .animation(.default, value: selectedTab)
                    .transition(.move(edge: .trailing))
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var calendarViewSection: some View {
        let calendarViewModel = CalendarViewModel(currentDate: currentDate, calendarManager: calendarManager)
        let eventViewModel = EventViewModel(calendarManager: calendarManager)
        return KairosCalendar(calendarViewModel: calendarViewModel, eventViewModel: eventViewModel)
    }

    // Adjustments for the addButton within ContentView
    private var addButton: some View {
        Button(action: {
            showingAddEventView = true
        }) {
            Image(systemName: "plus")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
        // Position the button at the bottom right corner of the screen
        .padding(.trailing, 25) // Right padding
        .padding(.bottom, 25)   // Bottom padding
        .sheet(isPresented: $showingAddEventView) {
            AddEventView(isPresented: $showingAddEventView, eventViewModel: EventViewModel(calendarManager: calendarManager), selectedDate: currentDate) {
                currentDate = currentDate // Refresh or update if necessary
            }
        }
    }

    enum Tab {
        case social, planner, calendar, chat
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
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
