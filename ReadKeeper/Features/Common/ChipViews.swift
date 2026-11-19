import SwiftUI

/// Lays out views left to right, wrapping onto new lines like words in a paragraph.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct ChipView: View {
    let text: String
    var isSelected = true
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }
        }
        .font(.footnote.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(isSelected ? Theme.accent : Theme.ink.opacity(0.7))
        .background(isSelected ? Theme.accent.opacity(0.14) : Theme.ink.opacity(0.06), in: Capsule())
    }
}

/// Edit a list of tropes or tags: remove existing chips, add your own, or pick from suggestions.
struct ChipEditor: View {
    let placeholder: String
    @Binding var items: [String]
    var suggestions: [String] = []

    @State private var newItem = ""

    private var remainingSuggestions: [String] {
        suggestions.filter { suggestion in
            !items.contains { $0.caseInsensitiveCompare(suggestion) == .orderedSame }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !items.isEmpty {
                FlowLayout {
                    ForEach(items, id: \.self) { item in
                        Button {
                            items = TagList.removing(item, from: items)
                        } label: {
                            ChipView(text: item, isSelected: true, systemImage: "xmark")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(item)")
                    }
                }
            }

            HStack {
                TextField(placeholder, text: $newItem)
                    .textInputAutocapitalization(.sentences)
                    .onSubmit(add)
                Button("Add", action: add)
                    .disabled(newItem.nilIfBlank == nil)
            }

            if !remainingSuggestions.isEmpty {
                FlowLayout {
                    ForEach(remainingSuggestions, id: \.self) { suggestion in
                        Button {
                            items = TagList.adding(suggestion, to: items)
                        } label: {
                            ChipView(text: suggestion, isSelected: false, systemImage: "plus")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(suggestion)")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func add() {
        items = TagList.adding(newItem, to: items)
        newItem = ""
    }
}

/// A slim rounded progress bar.
struct ReadingProgressBar: View {
    let fraction: Double
    var height: Double = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.1))
                Capsule()
                    .fill(LinearGradient(
                        colors: [Theme.accent.opacity(0.7), Theme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(CGFloat(height), proxy.size.width * CGFloat(min(max(fraction, 0), 1))))
                    .opacity(fraction > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}
