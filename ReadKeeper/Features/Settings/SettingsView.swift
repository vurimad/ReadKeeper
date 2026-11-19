import SwiftUI

struct SettingsView: View {
    @AppStorage(TiltMotion.enabledKey) private var tiltEnabled = true
    @State private var showingImportExport = LaunchOptions.opensImportExport

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ImportExportView()
                    } label: {
                        Label("Import & Export", systemImage: "arrow.up.arrow.down.square")
                    }
                } header: {
                    Text("Your library")
                } footer: {
                    Text("Bring your books from Goodreads or StoryGraph, or save a copy of your library.")
                }

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
            .navigationDestination(isPresented: $showingImportExport) {
                ImportExportView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
