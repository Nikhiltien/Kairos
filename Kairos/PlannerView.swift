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
    static let shared = PlannerViewModel() // temporarily static
    @Published var tasks: [Task] = []

    init() {
        loadTasks()
    }

    private func loadTasks() {
        // Implement loading logic, potentially decoding from a persistent store
        // This example uses UserDefaults for simplicity; replace with your data store logic
        if let tasksData = UserDefaults.standard.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            tasks = decodedTasks
        }
    }

    private func saveTasks() {
        // Implement saving logic, potentially encoding to a persistent store
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "tasks")
        }
    }

    func addTask(title: String, startDate: Date, endDate: Date) {
        let newTask = Task(id: UUID().uuidString, title: title, startDate: startDate, endDate: endDate, actionType: .add, arguments: [:])
        tasks.append(newTask)
        saveTasks()
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
