//
//  KairosCalendar.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import Foundation
import SwiftUI
import EventKit

struct KairosCalendar_Previews: PreviewProvider {
    static var previews: some View {
        let calendarManager = CalendarManager()
        let dummyEventViewModel = EventViewModel(calendarManager: calendarManager)
        let dummyEvents: [IdentifiableEvent] = [
            IdentifiableEvent(event: calendarManager.createEvent()),
            IdentifiableEvent(event: calendarManager.createEvent())
        ]
        return KairosCalendar(calendarViewModel: CalendarViewModel(currentDate: Date(), calendarManager: calendarManager), eventViewModel: dummyEventViewModel)
            .environmentObject(dummyEventViewModel)
            .onAppear {
                dummyEventViewModel.events = dummyEvents
            }
    }
}


struct KairosCalendar: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @StateObject private var eventViewModel: EventViewModel

    init(calendarViewModel: CalendarViewModel, eventViewModel: EventViewModel) {
        self._calendarViewModel = ObservedObject(wrappedValue: calendarViewModel)
        self._eventViewModel = StateObject(wrappedValue: eventViewModel)
    }

    var body: some View {
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
    @Published var events: [IdentifiableEvent] = []
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
                self?.events = events.map(IdentifiableEvent.init)
            }
        }
    }
    
    func updateEvent(event: IdentifiableEvent, title: String?, startDate: Date?, endDate: Date?, completion: @escaping (Bool, Error?) -> Void) {
        calendarManager.modifyEvent(event: event.event, title: title, startDate: startDate, endDate: endDate, completion: completion)
    }

    func removeEvent(event: IdentifiableEvent, completion: @escaping (Bool, Error?) -> Void) {
        calendarManager.deleteEvent(event: event.event, completion: completion)
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
    @State private var showingEditView = false
    @State private var selectedEvent: IdentifiableEvent?

    var body: some View {
        List(eventViewModel.events, id: \.id) { identifiableEvent in
            EventRow(identifiableEvent: identifiableEvent, eventViewModel: eventViewModel, showingEditView: $showingEditView, selectedEvent: $selectedEvent, date: date)
        }
        .onAppear {
            print("EventListView appeared for date: \(date)")
            eventViewModel.loadEvents(for: date)
        }
        .sheet(isPresented: $showingEditView) {
            if let eventToEdit = selectedEvent {
                EditEventView(isPresented: $showingEditView, eventViewModel: eventViewModel, identifiableEvent: eventToEdit) {
                    print("Event updated")
                    eventViewModel.loadEvents(for: date)
                }
            } else {
                EmptyView() // Ensure a view is returned even when there is no selected event
            }
        }
    }
}

struct EventRow: View {
    var identifiableEvent: IdentifiableEvent
    @ObservedObject var eventViewModel: EventViewModel
    @Binding var showingEditView: Bool
    @Binding var selectedEvent: IdentifiableEvent?
    var date: Date

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading) {
            Text(identifiableEvent.event.title).font(.headline)
            HStack {
                Text("\(identifiableEvent.event.startDate, formatter: itemFormatter)") + Text(" - ") + Text("\(identifiableEvent.event.endDate, formatter: itemFormatter)")
            }
            HStack {
                Button("Edit") {
                    selectedEvent = identifiableEvent
                    showingEditView = true
                }
                .padding()
                .buttonStyle(PlainButtonStyle())

                Button("Delete") {
                    eventViewModel.removeEvent(event: identifiableEvent) { success, _ in
                        if success {
                            print("Event deleted successfully")
                            eventViewModel.loadEvents(for: date)
                        } else {
                            print("Failed to delete event")
                        }
                    }
                }
                .padding()
                .buttonStyle(PlainButtonStyle())
            }
        }
        .contentShape(Rectangle()) // Makes sure the entire VStack is tappable, not beyond its bounds.
        .onTapGesture {
            // This empty gesture is to prevent list row tap from propagating to edit/delete buttons.
        }
    }
}

struct EditEventView: View {
    @Binding var isPresented: Bool
    @ObservedObject var eventViewModel: EventViewModel
    var identifiableEvent: IdentifiableEvent
    var onEventUpdated: (() -> Void)?
    
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date

    init(isPresented: Binding<Bool>, eventViewModel: EventViewModel, identifiableEvent: IdentifiableEvent, onEventUpdated: (() -> Void)?) {
        self._isPresented = isPresented
        self.eventViewModel = eventViewModel
        self.identifiableEvent = identifiableEvent
        self.onEventUpdated = onEventUpdated
        _title = State(initialValue: identifiableEvent.event.title)
        _startDate = State(initialValue: identifiableEvent.event.startDate)
        _endDate = State(initialValue: identifiableEvent.event.endDate)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])

                Button("Save") {
                    print("Save button pressed for event: \(title)")
                    eventViewModel.updateEvent(event: identifiableEvent, title: title, startDate: startDate, endDate: endDate) { success, _ in
                        if success {
                            onEventUpdated?()
                            isPresented = false
                        } else {
                            print("Failed to update event")
                        }
                    }
                }
            }
            .navigationTitle("Edit Event")
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
                            // Assuming the event addition was successful; now we send the data to the server.
                            sendEventToServer(title: title, startDate: startDate, endDate: endDate) { success in
                                print("Event was sent to the server: \(success)")
                            }
                            onEventAdded?()  // Trigger any additional actions like updating the calendar.
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

struct IdentifiableEvent: Identifiable {
    let id: String
    let event: EKEvent
    
    init(event: EKEvent) {
        self.id = event.eventIdentifier ?? UUID().uuidString
        self.event = event
    }
}
