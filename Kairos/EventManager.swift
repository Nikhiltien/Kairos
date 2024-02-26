//
//  EventManager.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/25/24.
//

import Foundation
import SwiftUI

struct Event: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var allDay: Bool
    var startDate: Date
    var endDate: Date
    var category: String
    var peopleTags: [String]
    var locationTag: String
    var alertOption: String
    var notes: String
    var availabilityType: String
    var priority: Int
}

struct EventRow: View {
    var event: Event // Replace 'Event' with the actual type of your event

    var body: some View {
        HStack {
            // Customize this view to display event information appropriately
            Text(event.title) // Assuming 'event' has a 'title' property
            Spacer()
            // You can add more details or controls related to the event here
        }
        .padding()
    }
}

class EventManager {
    static let shared = EventManager()
    private let eventsKey = "storedEvents"
    
    func saveEvent(_ event: Event) {
        var events = fetchEvents() ?? []
        events.append(event)
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    func fetchEvents() -> [Event]? {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let events = try? JSONDecoder().decode([Event].self, from: data) {
            return events
        }
        return nil
    }
}
