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

class PlannerViewModel: ObservableObject {
    static let shared = PlannerViewModel()
    @Published var tasks: [Task] = []

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(receivedDataFromServer(_:)), name: NSNotification.Name("ReceivedDataFromServer"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func receivedDataFromServer(_ notification: Notification) {
        if let response = notification.userInfo?["response"] as? ServerResponse {
            DispatchQueue.main.async {
                let taskDescription = "Response from server: \(response.response)"
                self.addTask(description: taskDescription, actionType: .add, arguments: [:])
            }
        }
    }

    func addTask(description: String, actionType: Task.TaskAction, arguments: [String: Any]) {
        let newTask = Task(id: UUID().uuidString, description: description, actionType: actionType, arguments: arguments)
        DispatchQueue.main.async {
            self.tasks.append(newTask)
        }
    }

    func removeTask(task: Task) {
        DispatchQueue.main.async {
            self.tasks.removeAll { $0.id == task.id }
        }
    }

    func executeTask(_ task: Task, addAction: @escaping ([String: Any]) -> Void, editAction: @escaping ([String: Any]) -> Void, deleteAction: @escaping ([String: Any]) -> Void) {
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

struct PlannerView: View {
    @StateObject private var viewModel = PlannerViewModel.shared

    var addAction: ([String: Any]) -> Void
    var editAction: ([String: Any]) -> Void
    var deleteAction: ([String: Any]) -> Void

    @State private var isAddingTask = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.tasks.isEmpty {
                    Text("No tasks available").italic()
                } else {
                    ForEach($viewModel.tasks) { $task in
                        Button(task.description) {
                            viewModel.executeTask(task, addAction: addAction, editAction: editAction, deleteAction: deleteAction)
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
                TaskCreationView(addAction: { title, _, arguments in
                    viewModel.addTask(description: title, actionType: .add, arguments: arguments)
                })
            }
        }
    }
}

// The rest of your implementation should remain the same.


struct TaskCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    
    var addAction: (String, Task.TaskAction, [String: Any]) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                Button("Add Task") {
                    addAction(title, .add, ["startDate": startDate, "endDate": endDate])
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
