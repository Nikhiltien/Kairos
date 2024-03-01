//
//  PlannerView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import SwiftUI
import Foundation

// Task structure to define properties of tasks
struct Task: Identifiable {
    let id: String
    var description: String
    var actionType: TaskAction
    var arguments: [String: Any]

    enum TaskAction: String {
        case add, edit, delete
    }
}

// Main view for task planning
struct PlannerView: View {
    @State private var tasks: [Task] = []
    @State private var isAddingTask = false

    var addAction: ([String: Any]) -> Void
    var editAction: ([String: Any]) -> Void
    var deleteAction: ([String: Any]) -> Void

    var body: some View {
        NavigationView {
            List {
                if tasks.isEmpty {
                    Text("No tasks available").italic()
                } else {
                    ForEach($tasks) { $task in
                        Button(task.description) {
                            executeTask(task)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                removeTask(task: task)
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
                TaskCreationView(addAction: { description, startDate, endDate in
                    let taskArguments: [String: Any] = ["title": description, "startDate": startDate, "endDate": endDate]
                    addTask(description: description, actionType: .add, arguments: taskArguments)
                })
            }
        }
    }

    private func removeTask(task: Task) {
        tasks.removeAll(where: { $0.id == task.id })
    }

    private func addTask(description: String, actionType: Task.TaskAction, arguments: [String: Any]) {
        let newTask = Task(id: UUID().uuidString, description: description, actionType: actionType, arguments: arguments)
        tasks.append(newTask)
    }

    private func executeTask(_ task: Task) {
        switch task.actionType {
        case .add:
            addAction(task.arguments)
        case .edit:
            editAction(task.arguments)
        case .delete:
            deleteAction(task.arguments)
        }
    }
}

// View for creating a new task
struct TaskCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    
    var addAction: (String, Date, Date) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                Button("Add Task") {
                    addAction(title, startDate, endDate)
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
