import SwiftUI
import Charts
import KeyboardLoggerShared

struct TrendsView: View {
    let service: StatsQueryService

    @State private var trends: [DailyTrend] = []
    @State private var selectedDays = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Shortcuts")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedDays) {
                    Text("7d").tag(7)
                    Text("30d").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if trends.isEmpty {
                ContentUnavailableView("No trend data", systemImage: "chart.bar", description: Text("Use shortcuts for a few days to see trends"))
                    .frame(maxHeight: .infinity)
            } else {
                Chart(trends, id: \.day) { item in
                    BarMark(
                        x: .value("Day", shortDay(item.day)),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .chartYAxisLabel("Shortcuts")
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear(perform: load)
        .onChange(of: selectedDays) { _, _ in load() }
    }

    private func load() {
        trends = (try? service.dailyShortcutTrend(days: selectedDays)) ?? []
    }

    private func shortDay(_ isoDay: String) -> String {
        // "2026-04-05" -> "Apr 5"
        let parts = isoDay.split(separator: "-")
        guard parts.count == 3, let month = Int(parts[1]), let day = Int(parts[2]) else { return isoDay }
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        guard month >= 1 && month <= 12 else { return isoDay }
        return "\(months[month]) \(day)"
    }
}
