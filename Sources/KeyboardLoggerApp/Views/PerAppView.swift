import SwiftUI
import KeyboardLoggerShared

struct PerAppView: View {
    let service: StatsQueryService

    @State private var summaries: [AppSummary] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per-App Breakdown")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            if summaries.isEmpty {
                ContentUnavailableView("No app data", systemImage: "app.dashed", description: Text("App usage will appear here"))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(summaries.enumerated()), id: \.offset) { _, summary in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(summary.appName)
                                    .font(.system(.body, weight: .medium))
                                HStack(spacing: 16) {
                                    Label("\(summary.shortcuts)", systemImage: "command")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    Label("\(summary.keystrokes)", systemImage: "keyboard")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let (from, to) = AppConstants.dateRange(for: "today")
        summaries = (try? service.perAppSummary(from: from, to: to)) ?? []
    }
}
