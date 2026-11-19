import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("No ads, ever", systemImage: "nosign")
                    Label("No AI art", systemImage: "paintbrush.pointed")
                    Label("Your books stay on your devices", systemImage: "lock")
                } header: {
                    Text("Our promise")
                }

                Section("About") {
                    LabeledContent("Version", value: AppInfo.versionString)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
