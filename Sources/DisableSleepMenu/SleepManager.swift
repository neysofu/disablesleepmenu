import Foundation
import Combine

class SleepManager: ObservableObject {
    @Published var isDisabled: Bool = false
    private var timer: Timer?

    init() {
        refresh()
        // Poll every 5 seconds in case state changes externally
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["/usr/bin/pmset", "disablesleep", newValue ? "1" : "0"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                isDisabled = newValue
            }
        } catch {
            print("Error toggling sleep: \(error)")
        }
    }
}
