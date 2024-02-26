import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool

    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack {
            // Displaying the month and year in a newspaper-esque font
            Text(viewModel.currentMonth)
                .font(.custom("AmericanTypewriter", size: 24)) // Choose a font that suits your newspaper style
                .padding()

            // Day of the week headers
            HStack {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }

            // Display the grid of days
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(viewModel.days) { day in
                    DayView(day: day, isToday: viewModel.isToday(day: day))
                        .onTapGesture {
                            viewModel.selectDay(day)
                            showingEventDetail.toggle()
                        }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded({ self.handleSwipe(translation: $0.translation.height) })
        )
        .animation(.easeInOut, value: viewModel.currentMonth)
    }

    private func handleSwipe(translation: CGFloat) {
        if translation < 0 {
            viewModel.goToPreviousMonth()
        } else if translation > 0 {
            viewModel.goToNextMonth()
        }
    }
}
