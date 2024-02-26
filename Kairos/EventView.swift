import SwiftUI

struct EventView: View {
    @State private var eventName: String = ""
    @State private var eventDate: Date = Date()
    @State private var allDay: Bool = false
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var repeatOption: String = "None"
    @State private var peopleTags: [String] = []
    @State private var locationTag: String = ""
    @State private var alertOptions = ["None", "15 min", "30 min", "1 hour", "2 hours", "24 hours", "Custom"]
    @State private var selectedAlertOption: String = "None"
    @State private var categories = ["None"] // Placeholder for category array
    @State private var selectedCategory: String = "None"
    @State private var notes: String = ""
    @State private var availabilityType: String = "Busy"
    @State private var priority: Int = 1
    @State private var showingMoreOptions: Bool = false
    @State private var isEditing: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $eventName)
                        .disabled(!isEditing)
                    DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                        .disabled(!isEditing)
                    Toggle("All-day", isOn: $allDay)
                        .disabled(!isEditing)
                    
                    if !allDay {
                        DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                            .disabled(!isEditing)
                        DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                            .disabled(!isEditing)
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .disabled(!isEditing)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(1...5, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!isEditing)
                }

                if showingMoreOptions {
                    Section(header: Text("More Options")) {
                        TextField("People Tags", text: Binding(get: {
                            self.peopleTags.joined(separator: ", ")
                        }, set: {
                            self.peopleTags = $0.components(separatedBy: ", ").filter { !$0.isEmpty }
                        }))
                        .disabled(!isEditing)
                        
                        TextField("Location", text: $locationTag)
                            .disabled(!isEditing)

                        Picker("Alert", selection: $selectedAlertOption) {
                            ForEach(alertOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .disabled(!isEditing)

                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .disabled(!isEditing)

                        TextField("Availability Type", text: $availabilityType)
                            .disabled(!isEditing)
                    }
                }

                Section {
                    Button(action: {
                        withAnimation {
                            showingMoreOptions.toggle()
                        }
                    }) {
                        Text(showingMoreOptions ? "Less Options" : "More Options")
                    }
                }

                Section {
                    Button(action: {
                        if isEditing {
                            saveEvent()
                        }
                        withAnimation {
                            isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                    }
                }
            }
            .navigationBarTitle("Event Details", displayMode: .inline)
        }
    }

    func saveEvent() {
        let event = Event(
            title: eventName,
            allDay: allDay,
            startDate: allDay ? eventDate : startTime,
            endDate: allDay ? eventDate : endTime,
            category: selectedCategory,
            peopleTags: peopleTags,
            locationTag: locationTag,
            alertOption: selectedAlertOption,
            notes: notes,
            availabilityType: availabilityType,
            priority: priority
        )
        
        EventManager.shared.saveEvent(event)
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventView()
    }
}
