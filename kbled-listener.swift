import Foundation
import IOKit
import IOKit.hid

// Background listener: watches for the keyboard described in kbled.env
// (same directory as this binary) to connect, watches its designated
// "trigger" key (KBLED_TRIGGER_USAGE_PAGE/USAGE), and toggles its backlight
// (KBLED_LED_ON_VALUE) on each key-down. Runs forever, and copes with the
// keyboard being unplugged/replugged at any time - it doesn't require the
// keyboard to already be connected when it starts.

let config = loadConfig()

func log(_ s: String) {
    let ts = DateFormatter()
    ts.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let line = "[\(ts.string(from: Date()))] \(s)\n"
    FileHandle.standardOutput.write(line.data(using: .utf8)!)
}

func readState() -> Bool {
    (try? String(contentsOfFile: config.stateFilePath, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) == "on"
}

func writeState(_ on: Bool) {
    try? (on ? "on" : "off").write(toFile: config.stateFilePath, atomically: true, encoding: .utf8)
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matching: [String: Any] = [
    kIOHIDVendorIDKey as String: config.vendorID,
    kIOHIDProductIDKey as String: config.productID,
    kIOHIDPrimaryUsagePageKey as String: 1,
    kIOHIDPrimaryUsageKey as String: 6
]
IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

let matchCallback: IOHIDDeviceCallback = { context, result, sender, device in
    log("Keyboard connected.")
}
let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
    log("Keyboard disconnected - will resume watching automatically when it's plugged back in.")
}
IOHIDManagerRegisterDeviceMatchingCallback(manager, matchCallback, nil)
IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, nil)

let inputCallback: IOHIDValueCallback = { context, result, sender, value in
    let element = IOHIDValueGetElement(value)
    guard Int(IOHIDElementGetUsagePage(element)) == config.triggerUsagePage,
          Int(IOHIDElementGetUsage(element)) == config.triggerUsage else { return }

    let pressed = IOHIDValueGetIntegerValue(value) != 0
    guard pressed else { return } // only act on key-down, ignore key-up

    let device = IOHIDElementGetDevice(element)
    let isOn = readState()
    let newValue: UInt8 = isOn ? 0x00 : config.ledOnValue
    var report = [newValue]
    let setResult = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, &report, report.count)
    if setResult == kIOReturnSuccess {
        writeState(!isOn)
        log(String(format: "Trigger key pressed -> sent 0x%02X (backlight %@)", newValue, !isOn ? "ON" : "OFF"))
    } else {
        log(String(format: "Trigger key pressed -> IOHIDDeviceSetReport FAILED (0x%08X)", setResult))
    }
}
IOHIDManagerRegisterInputValueCallback(manager, inputCallback, nil)

let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
guard openResult == kIOReturnSuccess else {
    log(String(format: "FATAL: IOHIDManagerOpen failed (0x%08X). Check System Settings > Privacy & Security > Input Monitoring - this program needs to be enabled there.", openResult))
    exit(1)
}

log("Started. Watching for VID=\(config.vendorID)/PID=\(config.productID) (connect it any time).")
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
CFRunLoopRun()
