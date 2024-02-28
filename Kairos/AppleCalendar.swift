//
//  AppleCalendar.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/26/24.
//

import Foundation
import EventKit

class CalendarManager {
    private let eventStore = EKEventStore()

    // MARK: - Authorization
    func requestEventAccess(completion: @escaping (Bool, Error?) -> Void) {
        if eventStore.responds(to: #selector(EKEventStore.requestFullAccessToEvents(completion:))) {
            eventStore.requestFullAccessToEvents { (granted, error) in
                DispatchQueue.main.async {
                    completion(granted, error)
                }
            }
        } else {
            // Fallback for iOS versions prior to 17.0
            eventStore.requestAccess(to: .event) { (granted, error) in
                DispatchQueue.main.async {
                    completion(granted, error)
                }
            }
        }
    }
    
    // MARK: - Fetch Events
    func fetchEvents(from startDate: Date, to endDate: Date, completion: @escaping ([EKEvent]?, Error?) -> Void) {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let events = self.eventStore.events(matching: predicate)
            DispatchQueue.main.async {
                completion(events, nil)
            }
        }
    }
    
    // MARK: - Add Event
    func addEvent(title: String, startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        let newEvent = EKEvent(eventStore: self.eventStore)
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        newEvent.title = title
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }
    
    // MARK: - Modify Event
    func modifyEvent(event: EKEvent, title: String?, startDate: Date?, endDate: Date?, completion: @escaping (Bool, Error?) -> Void) {
        if let title = title {
            event.title = title
        }
        
        if let startDate = startDate {
            event.startDate = startDate
        }
        
        if let endDate = endDate {
            event.endDate = endDate
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }
    
    // MARK: - Delete Event
    func deleteEvent(event: EKEvent, completion: @escaping (Bool, Error?) -> Void) {
        do {
            try eventStore.remove(event, span: .thisEvent)
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }
    
    func generateDaysInMonth(for currentDate: Date, completion: @escaping ([KairosCalendar.Day]) -> Void) {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            completion([])
            return
        }
        
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        fetchEvents(from: startOfMonth, to: endOfMonth) { events, error in
            guard error == nil, let events = events else {
                completion([])
                return
            }

            let days = range.compactMap { day -> KairosCalendar.Day? in
                let dateComponents = DateComponents(year: calendar.component(.year, from: currentDate), month: calendar.component(.month, from: currentDate), day: day)
                guard let date = calendar.date(from: dateComponents) else { return nil }
                
                let hasEvent = events.contains(where: { event in
                    calendar.isDate(event.startDate, inSameDayAs: date)
                })
                
                return KairosCalendar.Day(number: String(day), hasEvent: hasEvent)
            }

            completion(days)
        }
    }
}
