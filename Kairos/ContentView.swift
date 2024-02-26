import SwiftUI

struct ContentView: View {
    @State private var showingEventDetail = false
    @State private var showingSettings = false
    @State private var selectedCalendarView = "M" // Default view is Month
    let calendarViewModel = CalendarViewModel()

    // Enum to manage calendar views more robustly
    enum CalendarViewOption: String, CaseIterable {
        case day = "D"
        case week = "W"
        case month = "M"
        case schedule = "S"
        
        var title: String {
            self.rawValue
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedCalendarView) {
                    ForEach(CalendarViewOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option.title)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Dynamically switch views based on the Picker's selection
                Group {
                    switch selectedCalendarView {
//                    case CalendarViewOption.day.title:
//                        DayView() // Placeholder - Implement your DayView
                    case CalendarViewOption.week.title:
                        WeekView() // Placeholder - Implement your WeekView
                    case CalendarViewOption.month.title:
                        MonthView(viewModel: calendarViewModel, showingEventDetail: $showingEventDetail)
                    case CalendarViewOption.schedule.title:
                        ScheduleView() // Placeholder - Implement your ScheduleView
                    default:
                        MonthView(viewModel: calendarViewModel, showingEventDetail: $showingEventDetail)
                    }
                }
                .transition(.slide)
            }
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
                EventDetailView() // Placeholder - Implement your detailed event view
            }
//            .sheet(isPresented: $showingSettings) {
//                SettingsView() // Placeholder - Implement your settings view
//            }
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

// Define these view placeholders as separate structs if they are not already implemented.
struct WeekView: View {
    var body: some View {
        Text("Week View Placeholder") // Implement your WeekView content
    }
}

struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool

    var body: some View {
        VStack {
            Text(viewModel.currentMonth)
                .font(.custom("AmericanTypewriter", size: 30)) // Larger font size for month and year
                .padding()

            CalendarView(viewModel: viewModel, showingEventDetail: $showingEventDetail) // Assuming CalendarView is your detailed month view
        }
    }
}

struct ScheduleView: View {
    var body: some View {
        Text("Schedule View Placeholder") // Implement your ScheduleView content
    }
}

// Assume EventDetailView and SettingsView are defined elsewhere or replace with actual implementation.
