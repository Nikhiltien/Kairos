import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool
    @State private var selectedDay: Day?

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
                    DayView(day: day, isToday: viewModel.isToday(day: day))
                        .onTapGesture {
                            selectedDay = day
                            showingEventDetail = true
                        }
                }
            }
        }
        .sheet(isPresented: $showingEventDetail) {
            // Pass required data to EventDetailView, for now we assume it's for a new event
            EventDetailView()
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded({ self.handleSwipe(translation: $0.translation.height) })
        )
        .animation(.easeInOut, value: viewModel.currentMonth)
    }

    private func handleSwipe(translation: CGFloat) {
        if translation > 0 {
            viewModel.goToPreviousMonth()
        } else if translation < 0 {
            viewModel.goToNextMonth()
        }
    }
}
