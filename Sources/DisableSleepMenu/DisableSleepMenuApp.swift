import SwiftUI
import ServiceManagement

@main
struct DisableSleepMenuApp: App {
    @StateObject private var sleepManager: SleepManager
    @State private var launchAtLogin = false

    init() {
        SleepManager.runReenableHelperIfNeeded()
        _sleepManager = StateObject(wrappedValue: SleepManager())
    }

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 4) {
                Text(sleepManager.statusText)
                    .font(.headline)

                Divider()

                Button(sleepManager.isDisabled ? "Enable Sleep" : "Disable Sleep") {
                    sleepManager.toggle()
                }
                .keyboardShortcut("t")

                Button("Disable for 2 Hours") {
                    sleepManager.disableFor(hours: 2)
                }

                Button("Disable for 4 Hours") {
                    sleepManager.disableFor(hours: 4)
                }

                Button("Disable for 8 Hours") {
                    sleepManager.disableFor(hours: 8)
                }

                Divider()

                Toggle("Start at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(4)
            .onAppear {
                sleepManager.refresh()
                launchAtLogin = getLaunchAtLogin()
            }
        } label: {
            Image(systemName: sleepManager.isDisabled || sleepManager.hasTimedDisable ? "moon.zzz.fill" : "moon.zzz")
        }
    }

    private func getLaunchAtLogin() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
}
