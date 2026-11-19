import SwiftUI

struct SettingsView: View {
    @AppStorage(TiltMotion.enabledKey) private var tiltEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Tilt effect", isOn: $tiltEnabled)
                        .tint(Theme.accent)
                } header: {
                    Text("Shelf")
                } footer: {
                    Text("The bookshelf moves gently when you tilt your phone. It's always off when Reduce Motion is on.")
                }

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
