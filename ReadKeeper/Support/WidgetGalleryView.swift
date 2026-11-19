#if DEBUG
import SwiftData
import SwiftUI
import WidgetKit

/// Debug-only page that draws every widget at its real size, for CI screenshots
/// (the Simulator can't add widgets to the Home Screen automatically).
struct WidgetGalleryView: View {
    @Query private var books: [Book]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let snapshot = WidgetRefresher.makeSnapshot(
            books: books,
            goal: UserDefaults.standard.integer(forKey: ReadingGoal.storageKey)
        )
        let now = Date.now

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Home Screen")
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 16) {
                    homeWidget(width: 158) {
                        CurrentlyReadingWidgetContent(family: .systemSmall, snapshot: snapshot, date: now)
                    }
                    homeWidget(width: 158) {
                        StreakGoalWidgetContent(family: .systemSmall, snapshot: snapshot, date: now)
                    }
                }
                homeWidget(width: 332) {
                    CurrentlyReadingWidgetContent(family: .systemMedium, snapshot: snapshot, date: now)
                }

                Text("Lock Screen")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                HStack(spacing: 14) {
                    lockWidget(width: 72, height: 72, circle: true) {
                        CurrentlyReadingWidgetContent(family: .accessoryCircular, snapshot: snapshot, date: now)
                    }
                    lockWidget(width: 72, height: 72, circle: true) {
                        StreakGoalWidgetContent(family: .accessoryCircular, snapshot: snapshot, date: now)
                    }
                    lockWidget(width: 160, height: 72, circle: false) {
                        CurrentlyReadingWidgetContent(family: .accessoryRectangular, snapshot: snapshot, date: now)
                    }
                }
                lockWidget(width: 160, height: 72, circle: false) {
                    StreakGoalWidgetContent(family: .accessoryRectangular, snapshot: snapshot, date: now)
                }
                StreakGoalWidgetContent(family: .accessoryInline, snapshot: snapshot, date: now)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .padding(.top, 30)
        }
        .background(
            LinearGradient(colors: [Color(red: 0.35, green: 0.25, blue: 0.45), Color(red: 0.85, green: 0.5, blue: 0.4)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .overlay(alignment: .topTrailing) {
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }

    private func homeWidget<Content: View>(width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(width: width, height: 158)
            .background(
                LinearGradient(colors: [Theme.card, Theme.cardGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }

    private func lockWidget<Content: View>(width: CGFloat, height: CGFloat, circle: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundStyle(.white)
            .tint(.white)
            .padding(circle ? 0 : 8)
            .frame(width: width, height: height)
            .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: circle ? height / 2 : 14, style: .continuous))
            .environment(\.colorScheme, .dark)
    }
}
#endif
