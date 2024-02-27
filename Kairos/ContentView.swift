//
//  ContentView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @State private var currentDate = Date()
    let calendarManager = CalendarManager()

    var body: some View {
        let calendarViewModel = CalendarViewModel(currentDate: currentDate, calendarManager: calendarManager)
        let eventViewModel = EventViewModel(calendarManager: calendarManager)
        
        KairosCalendar(calendarViewModel: calendarViewModel, eventViewModel: eventViewModel)
    }
}
