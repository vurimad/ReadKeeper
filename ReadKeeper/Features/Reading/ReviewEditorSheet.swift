import SwiftData
import SwiftUI

/// Rating, spice level, tropes, tags and a written review.
struct ReviewEditorSheet: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Double?
    @State private var spiceLevel: Int?
    @State private var tropes: [String]
    @State private var tags: [String]
    @State private var review: String

    init(book: Book) {
        self.book = book
        _rating = State(initialValue: book.rating)
        _spiceLevel = State(initialValue: book.spiceLevel)
        _tropes = State(initialValue: book.tropes)
        _tags = State(initialValue: book.tags)
        _review = State(initialValue: book.review ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        StarRatingView(rating: $rating)
                        Spacer()
                        if rating != nil {
                            Button("Clear") { rating = nil }
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Rating")
                } footer: {
                    Text("Tap or slide across the stars. Half stars work too.")
                }

                Section("Spice level") {
                    SpiceLevelView(level: $spiceLevel)
                        .padding(.vertical, 4)
                }

                Section("Tropes") {
                    ChipEditor(placeholder: "Add a trope", items: $tropes, suggestions: TagList.tropeSuggestions)
                }

                Section("Tags") {
                    ChipEditor(placeholder: "Add a tag, e.g. book club", items: $tags)
                }

                Section("Review") {
                    TextEditor(text: $review)
                        .frame(minHeight: 140)
                        .overlay(alignment: .topLeading) {
                            if review.isEmpty {
                                Text("What did you think?")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .navigationTitle("Your Thoughts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
    }

    private func save() {
        book.rating = rating
        book.spiceLevel = (spiceLevel ?? 0) == 0 ? nil : spiceLevel
        book.tropes = tropes
        book.tags = tags
        book.review = review.nilIfBlank
        try? modelContext.save()
        dismiss()
    }
}

/// Save a favorite passage.
struct AddQuoteSheet: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var pageText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote") {
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                        .fontDesign(.serif)
                }
                Section {
                    TextField("Page (optional)", text: $pageText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(text.nilIfBlank == nil)
                }
            }
        }
    }

    private func save() {
        guard let value = text.nilIfBlank else { return }
        let quote = Quote(text: value, page: Int(pageText.trimmed))
        modelContext.insert(quote)
        quote.book = book
        try? modelContext.save()
        dismiss()
    }
}

/// Set or remove the yearly book goal.
struct GoalEditorSheet: View {
    @Binding var goal: Int
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Int

    init(goal: Binding<Int>) {
        _goal = goal
        _draft = State(initialValue: goal.wrappedValue > 0 ? goal.wrappedValue : 12)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $draft, in: ReadingGoal.range) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(draft)")
                                .font(.system(size: 40, weight: .bold, design: .serif))
                                .monospacedDigit()
                            Text(draft == 1 ? "book" : "books")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("About \(paceText) to reach it.")
                }

                if goal > 0 {
                    Section {
                        Button("Remove Goal", role: .destructive) {
                            goal = 0
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("\(Calendar.current.component(.year, from: .now)) Reading Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        goal = draft
                        dismiss()
                    }
                }
            }
        }
    }

    private var paceText: String {
        let perMonth = Double(draft) / 12
        if perMonth >= 1 {
            return "\(String(format: perMonth.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", perMonth)) books a month"
        }
        return "1 book every \(Int((12 / Double(draft)).rounded())) months"
    }
}
