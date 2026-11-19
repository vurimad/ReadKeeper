import SwiftData
import SwiftUI

/// "Where are you now?" Updates reading progress for today or a past day.
struct LogProgressSheet: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var unit: ProgressUnit
    @State private var pageText: String
    @State private var percent: Double
    @State private var listenedMinutes: Int
    @State private var totalPagesText: String
    @State private var totalLengthMinutes: Int
    @State private var speed: Double
    @State private var date = Date.now
    @State private var markFinished = false

    init(book: Book) {
        self.book = book
        let unit = book.progressUnit
        _unit = State(initialValue: unit)
        _pageText = State(initialValue: unit == .pages && book.progressValue > 0 ? String(Int(book.progressValue)) : "")
        _percent = State(initialValue: unit == .percent ? book.progressValue : 0)
        _listenedMinutes = State(initialValue: unit == .minutes ? Int(book.progressValue) : 0)
        _totalPagesText = State(initialValue: book.pageCount.map(String.init) ?? "")
        _totalLengthMinutes = State(initialValue: book.totalMinutes ?? 0)
        _speed = State(initialValue: book.playbackSpeed)
    }

    // MARK: Derived values

    private var startValue: Double {
        unit == book.progressUnit ? book.progressValue : 0
    }

    private var newValue: Double? {
        switch unit {
        case .pages:
            return Int(pageText.trimmed).map(Double.init)
        case .percent:
            return percent
        case .minutes:
            return Double(listenedMinutes)
        }
    }

    private var total: Double? {
        switch unit {
        case .pages:
            return Int(totalPagesText.trimmed).flatMap { $0 > 0 ? Double($0) : nil }
        case .percent:
            return 100
        case .minutes:
            return totalLengthMinutes > 0 ? Double(totalLengthMinutes) : nil
        }
    }

    private var canSave: Bool {
        markFinished || (newValue != nil && newValue != startValue)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Track by", selection: $unit) {
                        ForEach(ProgressUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    switch unit {
                    case .pages: pagesInput
                    case .percent: percentInput
                    case .minutes: timeInput
                    }
                } header: {
                    Text("Where are you now?")
                } footer: {
                    if let newValue, newValue != startValue {
                        Text(ProgressMath.deltaText(newValue - startValue, unit: unit))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }

                Section {
                    DatePicker("Day", selection: $date, in: ...Date.now, displayedComponents: .date)
                } footer: {
                    Text("Forgot to log? Pick the day you read. Your streak counts it.")
                }

                Section {
                    Toggle("I finished this book", isOn: $markFinished)
                        .tint(Theme.accent)
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onChange(of: newValue) { _, value in
                if let value, let total, value >= total {
                    markFinished = true
                }
            }
        }
    }

    private var pagesInput: some View {
        Group {
            HStack {
                Text("Page")
                TextField("0", text: $pageText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                if total == nil {
                    Text("of").foregroundStyle(.secondary)
                    TextField("total", text: $totalPagesText)
                        .keyboardType(.numberPad)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("of \(Int(total ?? 0))").foregroundStyle(.secondary)
                }
            }
            quickButtons([10, 25, 50], label: { "+\($0)" }) { amount in
                let current = Int(pageText.trimmed) ?? Int(startValue)
                pageText = String(current + amount)
            }
        }
    }

    private var percentInput: some View {
        Group {
            HStack {
                Slider(value: $percent, in: 0...100, step: 1)
                    .tint(Theme.accent)
                Text("\(Int(percent))%")
                    .monospacedDigit()
                    .frame(width: 52, alignment: .trailing)
            }
            quickButtons([5, 10, 25], label: { "+\($0)%" }) { amount in
                percent = min(100, percent + Double(amount))
            }
        }
    }

    private var timeInput: some View {
        Group {
            DurationStepper(title: "Listened up to", minutes: $listenedMinutes)
            quickButtons([15, 30, 60], label: { ProgressMath.deltaText(Double($0), unit: .minutes) }) { amount in
                listenedMinutes += amount
            }
            DurationStepper(title: "Audiobook length", minutes: $totalLengthMinutes)
            Picker("Playback speed", selection: $speed) {
                ForEach(ProgressMath.playbackSpeeds, id: \.self) { speed in
                    Text(ProgressMath.speedText(speed)).tag(speed)
                }
            }
        }
    }

    private func quickButtons(_ amounts: [Int], label: @escaping (Int) -> String, action: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            ForEach(amounts, id: \.self) { amount in
                Button(label(amount)) { action(amount) }
                    .buttonStyle(.bordered)
                    .tint(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        if unit == .pages, let pages = Int(totalPagesText.trimmed), pages > 0 {
            book.pageCount = pages
        }
        if unit == .minutes {
            book.totalMinutes = totalLengthMinutes > 0 ? totalLengthMinutes : nil
            book.playbackSpeed = speed
        }
        book.logProgress(
            to: newValue ?? startValue,
            unit: unit,
            on: date,
            finished: markFinished,
            context: modelContext
        )
        try? modelContext.save()
        WidgetRefresher.refresh(context: modelContext)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

/// Hours and minutes stepper (5-minute steps for minutes).
struct DurationStepper: View {
    let title: String
    @Binding var minutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Stepper("\(minutes / 60) h", value: hours, in: 0...200)
                Stepper("\(minutes % 60) m", value: mins, in: 0...55, step: 5)
            }
            .monospacedDigit()
        }
    }

    private var hours: Binding<Int> {
        Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 })
    }

    private var mins: Binding<Int> {
        Binding(get: { minutes % 60 }, set: { minutes = (minutes / 60) * 60 + $0 })
    }
}
