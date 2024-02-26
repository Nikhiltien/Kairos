//
//  ContentView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/25/24.
//

import SwiftUI

struct ContentView: View {
    @State private var showingEventDetail = false
    @State private var showingSettings = false
    @State private var selectedCalendarView = CalendarViewOption.month
    @State private var selectedDay: Day? = nil
    let calendarViewModel = CalendarViewModel()
    let buttonColor = Color(red: 250/255, green: 249/255, blue: 237/255)

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
                // CalendarViewMode bar
                Picker("View", selection: $selectedCalendarView) {
                    ForEach(CalendarViewOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(buttonColor)
                .cornerRadius(8)

                // Display content based on the selected view
                Group {
                    switch selectedCalendarView {
                    case .day:
                        DayViewWrapper()
                    case .week:
                        WeekView()
                    case .month:
                        MonthView(viewModel: calendarViewModel, showingEventDetail: $showingEventDetail, selectedDay: $selectedDay)
                    case .schedule:
                        ScheduleView()
                    }
                }
                .transition(.slide)

                // Display events or "No Events" text
                ScrollView {
                    Group {
                        if let day = selectedDay, !day.events.isEmpty {
                            ForEach(day.events, id: \.self) { event in
                                EventRow(event: event) // Assuming this is your custom view for events.
                            }
                        } else {
                            Text("No Events")
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top) // Ensuring content aligns at the top.
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    print("Search tapped")
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(buttonColor)
                },
                trailing: HStack {
                    Button(action: {
                        calendarViewModel.goToCurrentMonth()
                    }) {
                        Image(systemName: "house.fill")
                            .foregroundColor(buttonColor)
                    }
                    
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(buttonColor)
                    }
                }
            )
            .sheet(isPresented: $showingEventDetail) {
                if let selectedDay = selectedDay {
                    EventView()
                } else {
                    Text("No event details available.")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingEventDetail.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .background(buttonColor)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                            .padding()
                    }
                }
            }
        )
    }
}

struct DayViewWrapper: View {
    var body: some View {
        Text("Day View Placeholder")
    }
}

struct WeekView: View {
    var body: some View {
        Text("Week View Placeholder")
    }
}

struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool
    @Binding var selectedDay: Day?

    var body: some View {
        VStack {
            Text(viewModel.currentMonth)
                .font(.custom("AmericanTypewriter", size: 30))
                .padding()

            CalendarView(viewModel: viewModel, showingEventDetail: $showingEventDetail, selectedDay: $selectedDay)
        }
    }
}

struct ScheduleView: View {
    var body: some View {
        Text("Schedule View Placeholder")
    }
}
