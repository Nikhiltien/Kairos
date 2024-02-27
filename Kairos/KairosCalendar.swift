//
//  KairosCalendar.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import Foundation
import SwiftUI

struct KairosCalendar: View {
    @Binding var currentDate: Date
    @State private var days: [Day] = []
    let calendar = Calendar.current
    var calendarManager = CalendarManager()

    var body: some View {
        VStack {
            CalendarHeaderView(currentDate: $currentDate, changeMonth: changeMonth)
            
            DayOfWeekHeader()
            
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(days) { day in
                    DayView(day: day)
                }
            }
            .padding()
            .onAppear {
                self.updateDays()
            }
        }
    }
    
    private func changeMonth(by increment: Int) {
        if let adjustedDate = calendar.date(byAdding: .month, value: increment, to: currentDate) {
            currentDate = adjustedDate
            updateDays()
        }
    }

    private func updateDays() {
        calendarManager.generateDaysInMonth(for: currentDate) { days in
            self.days = days
        }
    }
    
    struct Day: Identifiable {
        let id = UUID()
        let number: String
        let hasEvent: Bool
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
    
    var body: some View {
        Text(day.number)
            .frame(minWidth: 32, minHeight: 32)  // Increase minimum dimensions as needed
            .padding(8)  // Adjust padding to ensure text fits well within the circle
            .background(day.hasEvent ? Color.green.opacity(0.3) : Color.clear)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.primary, lineWidth: 1)
            )
            .accessibilityLabel(day.hasEvent ? "Event on \(day.number)" : day.number)
            .font(.system(size: 16))  // You can adjust the font size if necessary
    }
}
