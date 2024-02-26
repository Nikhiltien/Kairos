//
//  CalendarView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/25/24.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool
    @Binding var selectedDay: Day?

    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack {
            // Day of the week headers
            HStack {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }

            // Display the grid of days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(viewModel.days) { day in
                    DayView(day: day) {
                        // This closure is what you pass to the DayView as the action
                        self.viewModel.selectDay(day)
                        self.selectedDay = day
                        self.showingEventDetail = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEventDetail) {
            if let selectedDay = selectedDay {
//                EventView(day: selectedDay) // Assuming EventView takes a day parameter
            } else {
                Text("No event details available.") // This is a placeholder text.
            }
        }
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded(handleSwipe)
        )
        .animation(.easeInOut, value: viewModel.currentMonth)
    }

    private func handleSwipe(_ gesture: DragGesture.Value) {
        let horizontalAmount = gesture.translation.width as CGFloat
        let verticalAmount = gesture.translation.height as CGFloat

        if abs(horizontalAmount) > abs(verticalAmount) {
            if horizontalAmount < 0 {
                viewModel.goToNextMonth()
            } else {
                viewModel.goToPreviousMonth()
            }
        } else {
            if verticalAmount > 0 {
                viewModel.goToPreviousMonth()
            } else {
                viewModel.goToNextMonth()
            }
        }
    }
}
