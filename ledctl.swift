import Foundation
import IOKit
import IOKit.hid

// Sends a single-byte HID output report to the keyboard interface described
// in kbled.env (same directory as this binary). Usage: ledctl <hex-byte>
// e.g. `ledctl 04` to turn the backlight on, `ledctl 00` to turn it off -
// exact values come from KBLED_LED_ON_VALUE in kbled.env for this device.

let config = loadConfig()

let value: UInt8 = {
    if CommandLine.arguments.count > 1 {
        let s = CommandLine.arguments[1].replacingOccurrences(of: "0x", with: "")
        return UInt8(s, radix: 16) ?? 0x00
    }
    return 0x00
}()

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matching: [String: Any] = [
    kIOHIDVendorIDKey as String: config.vendorID,
    kIOHIDProductIDKey as String: config.productID,
    kIOHIDPrimaryUsagePageKey as String: 1,
    kIOHIDPrimaryUsageKey as String: 6
]
IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

guard let deviceSet = IOHIDManagerCopyDevices(manager),
      let device = (deviceSet as? Set<IOHIDDevice>)?.first else {
    print("ERROR: keyboard interface (UsagePage=1/Usage=6) for VID=\(config.vendorID)/PID=\(config.productID) not found. Is it plugged in?")
    exit(1)
}

let openResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
guard openResult == kIOReturnSuccess else {
    print(String(format: "ERROR: Could not open HID device (0x%08X)", openResult))
    exit(1)
}

var report = [value]
let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, &report, report.count)
IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))

if result == kIOReturnSuccess {
    print(String(format: "SUCCESS: Sent LED output report 0x%02X", value))
} else {
    print(String(format: "ERROR: IOHIDDeviceSetReport failed (0x%08X)", result))
    exit(1)
}
