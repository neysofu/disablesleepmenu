import Foundation
import Combine

class SleepManager: ObservableObject {
    @Published var isDisabled: Bool = false
    @Published private var now = Date()
    private var refreshTimer: Timer?
    private var expiryTimer: Timer?
    private var timedDisableUntil: Date?
    private var timedDisableToken: String?

    private static let timedDisableUntilKey = "TimedDisableUntil"
    private static let timedDisableTokenKey = "TimedDisableToken"

    init() {
        loadTimedDisable()
        refresh()
        // Poll every 5 seconds in case state changes externally
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    var statusText: String {
        if let remaining = timedDisableRemaining {
            return "Sleep: Disabled (\(Self.formatDuration(remaining)) left)"
        }
        return isDisabled ? "Sleep: Disabled" : "Sleep: Enabled"
    }

    var hasTimedDisable: Bool {
        timedDisableRemaining != nil
    }

    func refresh() {
        now = Date()
        if let token = timedDisableToken,
           let until = timedDisableUntil,
           until <= now {
            completeTimedDisableIfCurrent(token: token)
            return
        }
        isDisabled = checkStatus()
    }

    private func checkStatus() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("SleepDisabled\t\t1")
            }
        } catch {
            print("Error checking sleep status: \(error)")
        }
        return false
    }

    func toggle() {
        let newValue = !isDisabled
        if Self.setSleepDisabled(newValue) {
            if !newValue {
                clearTimedDisable()
            }
            isDisabled = newValue
        }
    }

    func disableFor(hours: Int) {
        let allowedHours = [2, 4, 8]
        guard allowedHours.contains(hours) else {
            return
        }

        let seconds = TimeInterval(hours * 60 * 60)
        let until = Date().addingTimeInterval(seconds)
        let token = UUID().uuidString

        if Self.setSleepDisabled(true) {
            timedDisableUntil = until
            timedDisableToken = token
            saveTimedDisable(until: until, token: token)
            scheduleExpiryTimer(until: until, token: token)
            launchReenableHelper(after: seconds, token: token)
            isDisabled = true
            now = Date()
        }
    }

    static func runReenableHelperIfNeeded() {
        let arguments = CommandLine.arguments
        guard arguments.count == 4,
              arguments[1] == "--reenable-sleep-after",
              let seconds = TimeInterval(arguments[2]) else {
            return
        }

        let token = arguments[3]
        Thread.sleep(forTimeInterval: seconds)

        let defaults = UserDefaults.standard
        let savedToken = defaults.string(forKey: timedDisableTokenKey)
        let savedUntil = defaults.double(forKey: timedDisableUntilKey)

        if savedToken == token && savedUntil <= Date().timeIntervalSince1970 {
            _ = setSleepDisabled(false)
            defaults.removeObject(forKey: timedDisableUntilKey)
            defaults.removeObject(forKey: timedDisableTokenKey)
        }

        exit(0)
    }

    private var timedDisableRemaining: TimeInterval? {
        guard let until = timedDisableUntil else {
            return nil
        }

        let remaining = until.timeIntervalSince(now)
        return remaining > 0 ? remaining : nil
    }

    private func loadTimedDisable() {
        let defaults = UserDefaults.standard
        let savedUntil = defaults.double(forKey: Self.timedDisableUntilKey)
        guard savedUntil > 0,
              let token = defaults.string(forKey: Self.timedDisableTokenKey) else {
            return
        }

        let until = Date(timeIntervalSince1970: savedUntil)
        timedDisableUntil = until
        timedDisableToken = token

        if until <= Date() {
            completeTimedDisableIfCurrent(token: token)
        } else {
            scheduleExpiryTimer(until: until, token: token)
            launchReenableHelper(after: until.timeIntervalSinceNow, token: token)
        }
    }

    private func saveTimedDisable(until: Date, token: String) {
        let defaults = UserDefaults.standard
        defaults.set(until.timeIntervalSince1970, forKey: Self.timedDisableUntilKey)
        defaults.set(token, forKey: Self.timedDisableTokenKey)
    }

    private func clearTimedDisable() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        timedDisableUntil = nil
        timedDisableToken = nil

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.timedDisableUntilKey)
        defaults.removeObject(forKey: Self.timedDisableTokenKey)
    }

    private func scheduleExpiryTimer(until: Date, token: String) {
        expiryTimer?.invalidate()
        expiryTimer = Timer.scheduledTimer(withTimeInterval: max(0, until.timeIntervalSinceNow), repeats: false) { [weak self] _ in
            self?.completeTimedDisableIfCurrent(token: token)
        }
    }

    private func completeTimedDisableIfCurrent(token: String) {
        guard timedDisableToken == token else {
            return
        }

        if Self.setSleepDisabled(false) {
            clearTimedDisable()
            isDisabled = false
            now = Date()
        }
    }

    private func launchReenableHelper(after seconds: TimeInterval, token: String) {
        guard let executableURL = Bundle.main.executableURL else {
            return
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["--reenable-sleep-after", String(Int(seconds.rounded(.up))), token]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            print("Error launching timed sleep helper: \(error)")
        }
    }

    private static func setSleepDisabled(_ disabled: Bool) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", "/usr/bin/pmset", "disablesleep", disabled ? "1" : "0"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Error setting sleep disabled state: \(error)")
            return false
        }
    }

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = max(1, Int(ceil(duration / 60)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes)m"
        }

        if minutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(minutes)m"
    }
}
