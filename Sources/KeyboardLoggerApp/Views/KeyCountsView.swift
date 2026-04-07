import SwiftUI
import KeyboardLoggerShared

struct KeyCountsView: View {
    let service: StatsQueryService

    @State private var keyCounts: [KeyStat] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Key Usage")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            if keyCounts.isEmpty {
                ContentUnavailableView("No data yet", systemImage: "keyboard", description: Text("Key counts will appear here"))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(keyCounts.enumerated()), id: \.offset) { _, stat in
                            HStack {
                                Text(stat.key)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(width: 100, alignment: .leading)

                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(.green.opacity(0.3))
                                        .frame(width: max(4, geo.size.width * CGFloat(stat.count) / CGFloat(keyCounts.first?.count ?? 1)))
                                }
                                .frame(height: 16)

                                Text("\(stat.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            .frame(height: 24)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let (from, to) = AppConstants.dateRange(for: "today")
        keyCounts = (try? service.keyCounts(from: from, to: to, app: nil, limit: 30)) ?? []
    }
}
