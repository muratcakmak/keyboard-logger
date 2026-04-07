import SwiftUI
import KeyboardLoggerShared

struct TopShortcutsView: View {
    let service: StatsQueryService

    @State private var shortcuts: [ShortcutStat] = []
    @State private var selectedRange = "today"

    private let ranges = ["today", "week", "month"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Range", selection: $selectedRange) {
                ForEach(ranges, id: \.self) { Text($0.capitalized) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if shortcuts.isEmpty {
                ContentUnavailableView("No shortcuts yet", systemImage: "keyboard", description: Text("Start using shortcuts to see them here"))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(shortcuts.enumerated()), id: \.offset) { index, stat in
                            ShortcutRow(rank: index + 1, stat: stat, maxCount: shortcuts.first?.count ?? 1)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .onAppear(perform: load)
        .onChange(of: selectedRange) { _, _ in load() }
    }

    private func load() {
        let (from, to) = AppConstants.dateRange(for: selectedRange)
        shortcuts = (try? service.topShortcuts(from: from, to: to, app: nil, limit: 30)) ?? []
    }
}

struct ShortcutRow: View {
    let rank: Int
    let stat: ShortcutStat
    let maxCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("\(rank).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            Text(stat.combo)
                .font(.system(.body, design: .monospaced))
                .frame(width: 140, alignment: .leading)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(.blue.opacity(0.3))
                    .frame(width: max(4, geo.size.width * CGFloat(stat.count) / CGFloat(maxCount)))
            }
            .frame(height: 16)

            Text("\(stat.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(height: 24)
    }
}
