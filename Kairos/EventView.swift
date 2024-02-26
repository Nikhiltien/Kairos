import SwiftUI

struct EventDetailView: View {
    @State private var eventName: String = ""
    @State private var eventDate: Date = Date()
    @State private var allDay: Bool = false
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var peopleTags: [String] = []
    @State private var locationTag: String = ""
    @State private var alertOption: String = "None"
    @State private var selectedColor: Color = .blue
    @State private var notes: String = ""
    @State private var availability: String = "Busy"
    @State private var showingMoreOptions: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event", text: $eventName)
                    DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                    Toggle("All-day", isOn: $allDay)

                    if !allDay {
                        DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }

                if showingMoreOptions {
                    Section(header: Text("More Options")) {
                        TextField("People Tags", text: Binding(get: {
                            peopleTags.joined(separator: ", ")
                        }, set: {
                            peopleTags = $0.components(separatedBy: ", ")
                        }))
                        
                        TextField("Location", text: $locationTag)
                        
                        TextField("Alert", text: $alertOption)
                        
                        ColorPicker("Color", selection: $selectedColor)
                        
                       
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                        
                        TextField("Availability", text: $availability)
                    }
                }

                Section {
                    Button(action: {
                        withAnimation {
                            showingMoreOptions.toggle()
                        }
                    }) {
                        Text(showingMoreOptions ? "Less options" : "More options")
                    }
                }
            }
            .navigationBarTitle("Event Details", displayMode: .inline)
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView()
    }
}
