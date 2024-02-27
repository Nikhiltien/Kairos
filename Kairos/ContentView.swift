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

    var body: some View {
        KairosCalendar(currentDate: $currentDate)
    }
}
