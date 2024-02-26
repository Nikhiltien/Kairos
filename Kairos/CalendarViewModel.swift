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
}

struct DayView: View {
    var day: Day

    var body: some View {
        Text(day.number)
            .font(.body)
            .padding(8)
            .foregroundColor(day.number.isEmpty ? .clear : .black)
            .background(day.isSelected ? Color.yellow : Color(white: 0.95))
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
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        currentMonth = dateFormatter.string(from: currentDate)
        
        // Calculate the number of days and the starting day of the week for the month
        var components = DateComponents(year: year, month: month)
        components.day = 1
        let firstDayOfMonth = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numDays = range.count
        let startingWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // Adjusted for zero index
        
        // Generate Day objects
        days = (1..<(numDays + startingWeekday)).map { day in
            // Handle days of the previous month shown in the current calendar view
            if day < startingWeekday {
                return Day(number: "", isSelected: false, hasEvents: false)
            }
            // Adjust day number for zero-based index offset
            return Day(number: "\(day - startingWeekday + 1)", isSelected: false, hasEvents: false)
        }
    }
    
    func goToNextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        calculateMonth()
    }
    
    func goToPreviousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        calculateMonth()
    }
    
    func selectDay(_ day: Day) {
        // Logic to mark a day as selected and load events for that day
        // This could update `days` array or fetch event details to show in another view
    }
    
    func goToCurrentMonth() {
        currentDate = Date()
        calculateMonth()
    }
}
