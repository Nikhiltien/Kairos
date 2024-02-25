import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var showingEventDetail: Bool

    var body: some View {
        VStack {            // Display the current month and navigation controls
            HStack {
                Button("Prev") {
                    viewModel.goToPreviousMonth()
                }
                Spacer()
                Text(viewModel.currentMonth)
                Spacer()
                Button("Next") {
                    viewModel.goToNextMonth()
                }
            }
            .padding()

            // Display the grid of days
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                           ForEach(viewModel.days) { day in
                               DayView(day: day)
                                   .onTapGesture {
                                       viewModel.selectDay(day)
                                       showingEventDetail.toggle()  // Assuming you want to show event details on day tap
                       }
               }
           }
       }
   }
}
