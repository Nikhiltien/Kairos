//
//  PlannerView.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/27/24.
//

import SwiftUI
import Foundation

struct Task: Identifiable {
    let id: String
    var description: String
    var actionType: TaskAction
    var arguments: [String: Any]

    enum TaskAction: String {
        case add, edit, delete
    }

    // Tasks are identified and compared based on their IDs only, for simplicity.
    // This is a workaround as you cannot hash or compare closures.
}

struct PlannerView: View {
    @State private var tasks: [Task] = []

    var addAction: ([String: Any]) -> Void
    var editAction: ([String: Any]) -> Void
    var deleteAction: ([String: Any]) -> Void

    // Map each task action to its corresponding closure
    private var actions: [Task.TaskAction: ([String: Any]) -> Void] {
        [
            .add: addAction,
            .edit: editAction,
            .delete: deleteAction
        ]
    }

    var body: some View {
        NavigationView {
            List {
                if tasks.isEmpty {
                    Text("No tasks available").italic()
                } else {
                    ForEach($tasks) { $task in
                        Button(task.description) {
                            // Triggering the execution with correct context
                            self.executeTask(task)
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
        }
    }

    private func removeTask(task: Task) {
        tasks.removeAll { $0.id == task.id }
    }

    private func addTask() {
        let newTask = Task(
            id: UUID().uuidString,
            description: "Task \(tasks.count + 1)",
            actionType: .add,
            arguments: ["key": "value"]  // Example arguments
        )
        tasks.append(newTask)
    }

    // Function to execute a task
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
