import SwiftUI

struct ContentView: View {
    @State private var showingEventDetail = false

    // Create an instance of CalendarViewModel
    var calendarViewModel = CalendarViewModel()

    var body: some View {
        NavigationView {
            CalendarView(viewModel: calendarViewModel, showingEventDetail: $showingEventDetail)
                .navigationTitle("My Calendar")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingEventDetail.toggle()
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingEventDetail) {
                    EventDetailView()
                }
        }
    }
}
