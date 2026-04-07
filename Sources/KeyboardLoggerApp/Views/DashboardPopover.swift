import SwiftUI
import KeyboardLoggerShared

struct DashboardPopover: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            if let db = appState.databaseManager {
                let service = StatsQueryService(db: db)

                // Permission banner (non-blocking) or status indicator
                if !appState.isAccessibilityGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Accessibility permission needed")
                            .font(.caption)
                        Spacer()
                        Button("Grant") {
                            PermissionChecker.openAccessibilitySettings()
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.1))
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }

                Picker("", selection: $selectedTab) {
                    Text("Shortcuts").tag(0)
                    Text("Keys").tag(1)
                    Text("Apps").tag(2)
                    Text("Trends").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.top, 4)

                Divider()
                    .padding(.top, 8)

                switch selectedTab {
                case 0:
                    TopShortcutsView(service: service)
                case 1:
                    KeyCountsView(service: service)
                case 2:
                    PerAppView(service: service)
                case 3:
                    TrendsView(service: service)
                default:
                    EmptyView()
                }

                Divider()

                FooterView(service: service)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 360, height: 440)
    }
}

struct FooterView: View {
    let service: StatsQueryService

    @State private var shortcutsToday = 0
    @State private var keystrokesToday = 0

    var body: some View {
        HStack {
            Text("\(shortcutsToday) shortcuts")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(keystrokesToday) keystrokes")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear(perform: loadStats)
    }

    private func loadStats() {
        shortcutsToday = (try? service.totalShortcutsToday()) ?? 0
        keystrokesToday = (try? service.totalKeystrokesToday()) ?? 0
    }
}
