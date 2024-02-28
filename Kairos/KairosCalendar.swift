//
//  KairosCalendar.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import Foundation
import SwiftUI
import EventKit

struct KairosCalendar: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @StateObject private var eventViewModel: EventViewModel
    @State private var showingAddEventView = false

    init(calendarViewModel: CalendarViewModel, eventViewModel: EventViewModel) {
        self._calendarViewModel = ObservedObject(wrappedValue: calendarViewModel)
        self._eventViewModel = StateObject(wrappedValue: eventViewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                CalendarHeaderView(calendarViewModel: calendarViewModel)
                DayOfWeekHeader()

                LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                    ForEach(calendarViewModel.days) { day in
                        DayView(day: day, isSelected: isSelected(day: day))
                            .onTapGesture {
                                selectDate(day: day)
                            }
                    }
                }
                .padding()

                if let selectedDate = calendarViewModel.selectedDate {
                    EventListView(eventViewModel: eventViewModel, date: selectedDate)
                }
            }

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
            .padding()
        }
        .sheet(isPresented: $showingAddEventView) {
            AddEventView(isPresented: $showingAddEventView, eventViewModel: eventViewModel, selectedDate: calendarViewModel.selectedDate) {
                calendarViewModel.updateDays()  // Refresh the calendar days after adding an event.
            }
        }
    }

    private func isSelected(day: KairosCalendar.Day) -> Bool {
        guard let dayDate = calendarViewModel.getDate(for: day) else {
            return false
        }
        return Calendar.current.isDate(dayDate, inSameDayAs: calendarViewModel.selectedDate ?? Date())
    }

    private func selectDate(day: KairosCalendar.Day) {
        calendarViewModel.selectDate(day: day)
        if let newDate = calendarViewModel.getDate(for: day) {
            eventViewModel.loadEvents(for: newDate)
        }
    }

    struct Day: Identifiable {
        let id = UUID()
        let number: String
        let hasEvent: Bool
    }
}

class CalendarViewModel: ObservableObject {
    @Published var days: [KairosCalendar.Day] = []
    @Published var selectedDate: Date?
    var currentDate: Date {
        didSet {
            updateDays()
        }
    }
    private var calendarManager: CalendarManager

    init(currentDate: Date, calendarManager: CalendarManager) {
        self.currentDate = currentDate
        self.calendarManager = calendarManager
        updateDays()
    }

    func changeMonth(by increment: Int) {
        if let adjustedDate = Calendar.current.date(byAdding: .month, value: increment, to: currentDate) {
            currentDate = adjustedDate
        }
    }

    func updateDays() {
        calendarManager.generateDaysInMonth(for: currentDate) { [weak self] days in
            self?.days = days
        }
    }

    func selectDate(day: KairosCalendar.Day) {
        selectedDate = getDate(for: day)
    }

    func getDate(for day: KairosCalendar.Day) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month], from: currentDate)
        components.day = Int(day.number)
        return Calendar.current.date(from: components)
    }
}

class EventViewModel: ObservableObject {
    @Published var events: [EKEvent] = []
    private var calendarManager: CalendarManager

    init(calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
    }

    func addEvent(title: String, startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        calendarManager.addEvent(title: title, startDate: startDate, endDate: endDate, completion: completion)
    }

    func loadEvents(for date: Date) {
        guard let endOfDay = date.endOfDay else {
            print("Could not determine the end of the day.")
            return
        }

        calendarManager.fetchEvents(from: date.startOfDay, to: endOfDay) { [weak self] (events, error) in
            if let events = events {
                self?.events = events
            }
            // Optionally handle the error.
        }
    }
}

struct CalendarHeaderView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Button(action: { calendarViewModel.changeMonth(by: -1) }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString(from: calendarViewModel.currentDate))
                .font(.title)
                .accessibilityLabel(monthYearAccessibilityString(from: calendarViewModel.currentDate))

            Spacer()

            Button(action: { calendarViewModel.changeMonth(by: 1) }) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("Next month")
        }
        .padding()
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func monthYearAccessibilityString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct DayOfWeekHeader: View {
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .font(.caption)
            }
        }
    }
}

struct DayView: View {
    let day: KairosCalendar.Day
    var isSelected: Bool
    
    var body: some View {
        Text(day.number)
            .frame(minWidth: 32, minHeight: 32)
            .padding(8)
            .background(day.hasEvent ? Color.green.opacity(0.3) : Color.clear)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(isSelected ? Color.red : Color.primary, lineWidth: 1)
            )
            .accessibilityLabel(day.hasEvent ? "Event on \(day.number)" : day.number)
            .font(.system(size: 16))
    }
}

struct EventListView: View {
    @ObservedObject var eventViewModel: EventViewModel
    var date: Date

    var body: some View {
        List(eventViewModel.events, id: \.eventIdentifier) { event in
            VStack(alignment: .leading) {
                Text(event.title).font(.headline)
                Text(event.startDate, style: .time) + Text(" - ") + Text(event.endDate, style: .time)
            }
        }
        .onAppear {
            eventViewModel.loadEvents(for: date)
        }
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        let components = DateComponents(day: 1, second: -1)
        return Calendar.current.date(byAdding: components, to: self.startOfDay)
    }
}

// AddEventView.swift - Handles event creation UI and logic
struct AddEventView: View {
    @Binding var isPresented: Bool
    @ObservedObject var eventViewModel: EventViewModel
    var selectedDate: Date?
    var onEventAdded: (() -> Void)?

    @State private var title: String = ""
    @State private var startDate: Date
    @State private var endDate: Date

    init(isPresented: Binding<Bool>, eventViewModel: EventViewModel, selectedDate: Date?, onEventAdded: (() -> Void)?) {
        self._isPresented = isPresented
        self.eventViewModel = eventViewModel
        self.selectedDate = selectedDate
        self.onEventAdded = onEventAdded
        _startDate = State(initialValue: selectedDate ?? Date())
        _endDate = State(initialValue: (selectedDate ?? Date()).addingTimeInterval(3600))  // Default duration 1 hour
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])

                Button("Save") {
                    eventViewModel.addEvent(title: title, startDate: startDate, endDate: endDate) { success, _ in
                        if success {
                            self.onEventAdded?()  // This should trigger updateDays in CalendarViewModel.
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
