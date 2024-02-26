//
//  CalendarViewModel.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/25/24.
//

import Foundation
import SwiftUI

struct Day: Identifiable, Equatable {
    let id = UUID()
    let number: String
    var isSelected: Bool
    var hasEvents: Bool
    var isToday: Bool // Adding the isToday property here
    var events: [Event]
}

struct DayView: View {
    var day: Day
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.number)
                .font(.body)
                .padding(8)
                .frame(width: 40, height: 40)
                .foregroundColor(day.number.isEmpty ? .clear : .black)
                .background(day.isToday ? Color.red : day.isSelected ? Color.blue : Color(white: 0.95))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.gray, lineWidth: day.isToday ? 2 : 0)
                )
        }
        .accessibilityLabel(Text("Day \(day.number)"))
    }
}

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: String = ""
    @Published var days: [Day] = []
    
    private var currentDate = Date()
    private let calendar = Calendar.current
    
    init() {
        calculateMonth()
    }
    
    func calculateMonth() {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let firstDayOfMonth = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numDays = range.count
        let startingWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        currentMonth = dateFormatter.string(from: currentDate)

        days.removeAll()
        days.reserveCapacity(numDays + startingWeekday - 1)

        for day in 1..<(numDays + startingWeekday) {
            if day < startingWeekday {
                days.append(Day(number: "", isSelected: false, hasEvents: false, isToday: false, events: []))
            } else {
                let dayNumber = day - startingWeekday + 1
                let dateComponents = DateComponents(year: components.year, month: components.month, day: dayNumber)
                let dayDate = calendar.date(from: dateComponents)!
                let isToday = calendar.isDateInToday(dayDate)

                // Here you would determine the events for the day
                let dayEvents: [Event] = [] // Replace this with actual event fetching

                days.append(Day(number: "\(dayNumber)", isSelected: false, hasEvents: !dayEvents.isEmpty, isToday: isToday, events: dayEvents))
            }
        }
    }
    
    func isToday(day: Day) -> Bool {
        return day.isToday
    }
    
    func goToNextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        resetDaySelection()
        calculateMonth()
    }
    
    func goToPreviousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        resetDaySelection()
        calculateMonth()
    }
    
    func goToCurrentMonth() {
        currentDate = Date()
        resetDaySelection()
        calculateMonth()
    }
    
    private func resetDaySelection() {
        for index in days.indices {
            days[index].isSelected = false
        }
    }
    
    func selectDay(_ selectedDay: Day) {
        // Deselect all days
        for index in days.indices {
            days[index].isSelected = false
        }
        
        // Find the selected day and mark it as selected
        if let selectedIndex = days.firstIndex(where: { $0.id == selectedDay.id }) {
            days[selectedIndex].isSelected = true
            // Additional logic can be added here if you want to fetch or display events for the selected day
        }
    }
}
