import SwiftUI
import ServiceManagement

@main
struct DisableSleepMenuApp: App {
    @StateObject private var sleepManager = SleepManager()
    @State private var launchAtLogin = false

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 4) {
                Text(sleepManager.isDisabled ? "Sleep: Disabled" : "Sleep: Enabled")
                    .font(.headline)

                Divider()

                Button(sleepManager.isDisabled ? "Enable Sleep" : "Disable Sleep") {
                    sleepManager.toggle()
                }
                .keyboardShortcut("t")

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
                launchAtLogin = getLaunchAtLogin()
            }
        } label: {
            Image(systemName: sleepManager.isDisabled ? "moon.zzz.fill" : "moon.zzz")
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
