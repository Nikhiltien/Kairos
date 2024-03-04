//
//  PlannerView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import SwiftUI
import Foundation
import Combine

struct Task: Identifiable, Codable {
    let id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var actionType: TaskAction
    var arguments: [String: String] // Retained for potential additional metadata

    enum TaskAction: String, Codable {
        case add, edit, delete
    }
}

class PlannerViewModel: ObservableObject {
    static let shared = PlannerViewModel()
    @Published var tasks: [Task] = []

    init() {
        loadTasks()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAIAssistantResponse(notification:)), name: NSNotification.Name("AIAssistantResponseReceived"), object: nil)
    }

    @objc private func handleAIAssistantResponse(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let response = userInfo["response"] as? ServerResponse else {
            print("Invalid response structure.")
            return
        }

        // Extract JSON from the server response safely
        if let jsonData = extractJsonData(from: response.response) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedTask = try decoder.decode(Task.self, from: jsonData)

                switch decodedTask.actionType {
                    case .add:
                        // Generate a new UUID for new tasks, ignoring the 'id' from the AI assistant
                        addTask(title: decodedTask.title, startDate: decodedTask.startDate, endDate: decodedTask.endDate)
                    case .edit, .delete:
                        // For edit and delete actions, use the 'id' provided by the AI assistant
                        if let index = tasks.firstIndex(where: { $0.id == decodedTask.id }) {
                            if decodedTask.actionType == .edit {
                                tasks[index] = Task(id: decodedTask.id, title: decodedTask.title, startDate: decodedTask.startDate, endDate: decodedTask.endDate, actionType: .edit, arguments: decodedTask.arguments)
                            } else if decodedTask.actionType == .delete {
                                tasks.remove(at: index)
                            }
                        }
                }
                saveTasks()
            } catch {
                print("Error decoding task from AI response: \(error)")
                addErrorTask()
            }
        } else {
            print("No valid JSON found in AI response.")
            addErrorTask()
        }
    }

    private func extractJsonData(from response: String) -> Data? {
        if let jsonRangeStart = response.range(of: "{"),
           let jsonRangeEnd = response.range(of: "}", options: .backwards) {
            let jsonSubstring = response[jsonRangeStart.lowerBound...jsonRangeEnd.upperBound]
            return String(jsonSubstring).data(using: .utf8)
        }
        return nil
    }

    private func addErrorTask() {
        addTask(title: "ERROR!", startDate: Date(), endDate: Date())
    }

    func addTask(title: String, startDate: Date, endDate: Date) {
        // Generate a new Task with a local time zone based dates
        let userTimeZoneStartDate = convertToUserTimeZone(date: startDate)
        let userTimeZoneEndDate = convertToUserTimeZone(date: endDate)

        let newTask = Task(id: UUID().uuidString, title: title, startDate: userTimeZoneStartDate, endDate: userTimeZoneEndDate, actionType: .add, arguments: [:])
        tasks.append(newTask)
        saveTasks()
    }

    private func convertToUserTimeZone(date: Date) -> Date {
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: date))
        return date.addingTimeInterval(timeZoneOffset)
    }

    private func loadTasks() {
        if let tasksData = UserDefaults.standard.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            tasks = decodedTasks
        }
    }

    private func saveTasks() {
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "tasks")
        }
    }

    func removeTask(task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
}

struct PlannerView: View {
    @ObservedObject private var viewModel = PlannerViewModel.shared
    @State private var isAddingTask = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.tasks.isEmpty {
                    Text("No tasks available").italic()
                } else {
                    ForEach(viewModel.tasks) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title).font(.headline)
                                Text("Start: \(task.startDate, formatter: itemFormatter)")
                                Text("End: \(task.endDate, formatter: itemFormatter)")
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeTask(task: task)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Planned Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                TaskCreationView(addTask: viewModel.addTask)
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()


// The rest of your implementation should remain the same.


struct TaskCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()

    var addTask: (String, Date, Date) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                Button("Add Task") {
                    addTask(title, startDate, endDate)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            }
            .navigationTitle("Add New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
