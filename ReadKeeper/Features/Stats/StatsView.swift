import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No reading stats yet",
                systemImage: "chart.bar",
                description: Text("Finish your first book to see your year in reading.")
            )
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
}
