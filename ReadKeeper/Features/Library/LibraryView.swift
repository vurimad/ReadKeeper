import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Your library is empty",
                systemImage: "books.vertical",
                description: Text("Books you add will appear here, sorted into Reading, Want to Read, Read and DNF.")
            )
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
