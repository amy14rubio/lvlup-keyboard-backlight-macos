import Foundation

// Shared config loader for ledctl and kbled-listener. Both binaries live in
// the same install directory as kbled.env and read their settings from it at
// startup - nothing is compiled in, so the same binary works for any keyboard
// whose owner edits kbled.env with their own device's numbers.

struct KbledConfig {
    let vendorID: Int
    let productID: Int
    let ledOnValue: UInt8
    let triggerUsagePage: Int
    let triggerUsage: Int
    let stateFilePath: String
    let logFilePath: String
}

func loadConfig() -> KbledConfig {
    let exeDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    let envPath = exeDir.appendingPathComponent("kbled.env").path

    guard let contents = try? String(contentsOfFile: envPath, encoding: .utf8) else {
        FileHandle.standardError.write("FATAL: could not read config at \(envPath)\nDid you copy kbled.env.example to kbled.env and fill in your keyboard's numbers?\n".data(using: .utf8)!)
        exit(1)
    }

    var values: [String: String] = [:]
    for rawLine in contents.split(separator: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        guard !line.isEmpty, !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }
        let key = String(line[line.startIndex..<eq]).trimmingCharacters(in: .whitespaces)
        let value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
        values[key] = value
    }

    func require(_ key: String) -> String {
        guard let v = values[key], !v.isEmpty else {
            FileHandle.standardError.write("FATAL: \(key) is missing from \(envPath)\n".data(using: .utf8)!)
            exit(1)
        }
        return v
    }

    func int(_ key: String) -> Int {
        let raw = require(key)
        if raw.lowercased().hasPrefix("0x"), let v = Int(raw.dropFirst(2), radix: 16) { return v }
        guard let v = Int(raw) else {
            FileHandle.standardError.write("FATAL: \(key)=\(raw) in \(envPath) is not a valid number\n".data(using: .utf8)!)
            exit(1)
        }
        return v
    }

    return KbledConfig(
        vendorID: int("KBLED_VENDOR_ID"),
        productID: int("KBLED_PRODUCT_ID"),
        ledOnValue: UInt8(int("KBLED_LED_ON_VALUE")),
        triggerUsagePage: int("KBLED_TRIGGER_USAGE_PAGE"),
        triggerUsage: int("KBLED_TRIGGER_USAGE"),
        stateFilePath: exeDir.appendingPathComponent(".state").path,
        logFilePath: exeDir.appendingPathComponent("listener.log").path
    )
}
