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
            HStack {
                Button(action: {
                    self.changeMonth(by: -1)
                }) {
                    Image(systemName: "arrow.left")
                }

                Spacer()

                Text(monthYearString(from: currentDate))
                    .font(.title)

                Spacer()

                Button(action: {
                    self.changeMonth(by: 1)
                }) {
                    Image(systemName: "arrow.right")
                }
            }
            .padding()

            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(days, id: \.self.number) { day in
                    Text(day.number)
                        .padding()
                        .background(day.hasEvent ? Color.green : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
            .onAppear {
                self.updateDays()
            }
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, yyyy"
        return formatter.string(from: date)
    }

    private func changeMonth(by increment: Int) {
        if let adjustedDate = calendar.date(byAdding: .month, value: increment, to: currentDate) {
            currentDate = adjustedDate
            updateDays()
        }
    }

    private func updateDays() {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return
        }
        
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        calendarManager.fetchEvents(from: startOfMonth, to: endOfMonth) { events, error in
            guard let events = events else { return }
            
            self.days = range.compactMap { day -> Day? in
                let dayComponent = DateComponents(day: day - 1)
                guard let date = self.calendar.date(byAdding: dayComponent, to: startOfMonth) else { return nil }
                let dayEvents = events.filter { event in
                    self.calendar.isDate(event.startDate, inSameDayAs: date)
                }
                return Day(number: String(day), hasEvent: !dayEvents.isEmpty)
            }
        }
    }
    
    struct Day: Identifiable {
        let id = UUID()
        let number: String
        let hasEvent: Bool
    }
}
