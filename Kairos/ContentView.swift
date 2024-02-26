import SwiftUI

struct ContentView: View {
    @State private var showingEventDetail = false
    @State private var showingSettings = false
    @State private var selectedCalendarView = "M"
    let calendarViewOptions = ["D", "W", "M", "S"]
    
    var calendarViewModel = CalendarViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedCalendarView) {
                    ForEach(calendarViewOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                CalendarView(viewModel: calendarViewModel, showingEventDetail: $showingEventDetail)
                    .navigationBarItems(
                        leading: Button(action: {
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
                        Text("Settings Placeholder")
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
}
