import SwiftUI
import KeyboardLoggerShared

@main
struct KeyboardLoggerApp: App {
    @StateObject private var appState = AppState()

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        state.bootstrap()
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardPopover()
                .environmentObject(appState)
        } label: {
            Label("KeyboardLogger", systemImage: appState.isCapturing ? "keyboard.fill" : "keyboard")
        }
        .menuBarExtraStyle(.window)
    }
}
