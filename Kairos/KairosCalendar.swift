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
    @Binding var currentDate: Date
    @ObservedObject var calendarViewModel: CalendarViewModel
    @StateObject private var eventViewModel: EventViewModel

    private let calendar = Calendar.current // Defining the calendar instance

    init(currentDate: Binding<Date>, calendarManager: CalendarManager) {
        self._currentDate = currentDate
        self.calendarViewModel = CalendarViewModel(currentDate: currentDate.wrappedValue, calendarManager: calendarManager)
        self._eventViewModel = StateObject(wrappedValue: EventViewModel(calendarManager: calendarManager))
    }

    var body: some View {
        VStack {
            CalendarHeaderView(currentDate: $currentDate, changeMonth: calendarViewModel.changeMonth)
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
        .onChange(of: currentDate) { _ in
            calendarViewModel.changeMonth(by: 0)  // Triggers the days update
        }
    }

    private func isSelected(day: KairosCalendar.Day) -> Bool {
        guard let dayDate = getDate(for: day) else {
            return false
        }
        return calendar.isDate(dayDate, inSameDayAs: calendarViewModel.selectedDate ?? Date())
    }

    private func selectDate(day: KairosCalendar.Day) {
        if let newDate = getDate(for: day) {
            calendarViewModel.selectedDate = newDate
            eventViewModel.loadEvents(for: newDate)
        }
    }

    private func getDate(for day: KairosCalendar.Day) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy MM dd"
        let dateString = "\(calendar.component(.year, from: currentDate)) \(calendar.component(.month, from: currentDate)) \(day.number)"
        return dateFormatter.date(from: dateString)
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
    private var calendarManager: CalendarManager
    private var currentDate: Date {
        didSet {
            updateDays()
        }
    }

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

    private func updateDays() {
        calendarManager.generateDaysInMonth(for: currentDate) { [weak self] days in
            self?.days = days
        }
    }
}

class EventViewModel: ObservableObject {
    @Published var events: [EKEvent] = []
    private var calendarManager: CalendarManager

    init(calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
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
            // Handle the error accordingly.
        }
    }
}

struct CalendarHeaderView: View {
    @Binding var currentDate: Date
    let changeMonth: (Int) -> Void
    
    var body: some View {
        HStack {
            Button(action: { changeMonth(-1) }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString(from: currentDate))
                .font(.title)
                .accessibilityLabel(monthYearAccessibilityString(from: currentDate))

            Spacer()

            Button(action: { changeMonth(1) }) {
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
