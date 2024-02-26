import SwiftUI

struct SettingsView: View {
    @State private var isKairosAIAssistantEnabled = false
    @State private var isCalendarSyncEnabled = false
    @State private var showingProfile = false
    @Environment(\.presentationMode) var presentationMode

    private let backgroundColor = Color.black.opacity(0.7)
    private let textColor = Color.white
    private let premiumFeatureBorderColor = Color.blue
    private let premiumFeatureBorderWidth: CGFloat = 2

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                Form {
                    Section(header: Text("Premium Features").foregroundColor(textColor)) {
                        HStack {
                            Toggle("Kairos AI Assistant", isOn: $isKairosAIAssistantEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .labelsHidden()
                            Text("Kairos AI Assistant")
                                .foregroundColor(textColor)
                                .padding(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(premiumFeatureBorderColor, lineWidth: premiumFeatureBorderWidth)
                                )
                        }
                        .padding(.vertical, 5)
                    }
                    .headerProminence(.increased)
                    .listRowBackground(backgroundColor)

                    Section(header: Text("Integrations").foregroundColor(textColor)) {
                        Toggle("Sync with Google Calendar", isOn: $isCalendarSyncEnabled)
                            .foregroundColor(textColor)
                    }
                    .listRowBackground(backgroundColor)

                    Section(header: Text("Account").foregroundColor(textColor)) {
                        Button("Profile") {
                            showingProfile = true
                        }
                        .foregroundColor(textColor)
                        .sheet(isPresented: $showingProfile) {
                            ProfileView() // Implement this view as needed
                        }
                    }
                    .listRowBackground(backgroundColor)
                }
            }
            .navigationBarTitle("Settings", displayMode: .large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarTitleDisplayMode(.inline)
            .background(backgroundColor)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile Placeholder") // Replace with actual profile content
    }
}
