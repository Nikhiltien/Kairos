import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool

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

            // Display the grid of days with swipe gesture support for month navigation
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(viewModel.days) { day in
                    DayView(day: day)
                        .onTapGesture {
                            viewModel.selectDay(day)
                            showingEventDetail.toggle()
                        }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded({ self.handleSwipe(translation: $0.translation.width) })
            )
        }
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
