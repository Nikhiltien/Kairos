import SwiftUI

struct ContentView: View {
    @State private var showingEventDetail = false
    @State private var showingSettings = false
    // Create an instance of CalendarViewModel
    var calendarViewModel = CalendarViewModel()

    var body: some View {
        NavigationView {
            CalendarView(viewModel: calendarViewModel, showingEventDetail: $showingEventDetail)
                .navigationBarItems(
                    leading: Button(action: {
                        // Placeholder for search functionality
                        print("Search tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                    },
                    trailing: HStack {
                        Button(action: {
                            calendarViewModel.goToCurrentMonth()
                        }) {
                            Image(systemName: "house.fill")
                        }
                        
                        Button(action: {
                            showingSettings.toggle()
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                )

                .sheet(isPresented: $showingEventDetail) {
                    EventDetailView()
                }
                .sheet(isPresented: $showingSettings) {
                    Text("Settings Placeholder") // Replace with your SettingsView
                }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingEventDetail = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                            .padding()
                    }
                }
            }
        )
    }
}
