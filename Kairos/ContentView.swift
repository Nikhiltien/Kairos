import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            CalendarView()
                .navigationTitle("My Calendar")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Action to add a new event
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
