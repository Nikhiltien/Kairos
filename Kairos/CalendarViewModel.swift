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
}

struct DayView: View {
    var day: Day
    var isToday: Bool

    var body: some View {
        Text(day.number)
            .font(.body)
            .padding(8)
            .foregroundColor(day.number.isEmpty ? .clear : .black)
            .background(isToday ? Color.red : (day.isSelected ? Color.yellow : Color(white: 0.95)))
            .clipShape(Circle())
            .overlay(
                day.hasEvents ? Circle().stroke(Color.gray, lineWidth: 2) : nil
            )
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

        // Initialize days with correct capacity to avoid reallocation
        days.removeAll()
        days.reserveCapacity(numDays + startingWeekday - 1)

        // Fill in the days array
        for day in 1..<(numDays + startingWeekday) {
            if day < startingWeekday {
                days.append(Day(number: "", isSelected: false, hasEvents: false, isToday: false))
            } else {
                let dayNumber = day - startingWeekday + 1
                let dateComponents = DateComponents(year: components.year, month: components.month, day: dayNumber)
                let dayDate = calendar.date(from: dateComponents)!
                let isToday = calendar.isDateInToday(dayDate)
                days.append(Day(number: "\(dayNumber)", isSelected: false, hasEvents: false, isToday: isToday))
            }
        }
    }

    func isToday(day: Day) -> Bool {
        return day.isToday
    }
    
    func goToNextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        calculateMonth()
    }
    
    func goToPreviousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        calculateMonth()
    }
    
    func goToCurrentMonth() {
        currentDate = Date()
        calculateMonth()
    }
    
    func selectDay(_ day: Day) {
        // Logic to mark a day as selected and load events for that day
        // This could update `days` array or fetch event details to show in another view
    }
}
