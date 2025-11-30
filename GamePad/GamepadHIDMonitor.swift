//
//  GamePadMonitor.swift
//  GamePad
//
//  Created by Marco Luglio on 30/05/20.
//  Copyright © 2020 Marco Luglio. All rights reserved.
//

import Cocoa
import Foundation

import GameController

import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib
import IOKit.hid

//import ForceFeedback


final class GamepadHIDMonitor {

    // Make this optional to avoid implicit unwrap crashes when not yet set
    var joyConController: JoyConController?

    init() {
        //
    }

    @objc func setupHidObservers() {

        let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        let hidContext = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)

        let deviceCriteria: NSArray = [
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_GamePad
            ]
        ]

        // filter hid devices based on criteria above
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, deviceCriteria)

        // starts hid manager monitoring of devices
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) // also have to call IOHIDManagerUnscheduleFromRunLoop at some point
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone)) // also have to call IOHIDManagerClose at some point

        // registers a callback for gamepad being connected
        IOHIDManagerRegisterDeviceMatchingCallback(
            hidManager,
            {(context, result, sender, device) in

                // restoring the swift type of the pointer to void
                let caller = unsafeBitCast(context, to: GamepadHIDMonitor.self)

                // must call another function to avoid creating a closure, which is not supported for c functions
                return caller.hidDeviceAddedCallback(result, sender: sender!, device: device)

            },
            hidContext // reference to self (GamePadMonitor) that can be passed to c functions, essentially a pointer to void, meaning it can point to any type
        )

        // registers a callback for gamepad being disconnected
        IOHIDManagerRegisterDeviceRemovalCallback(
            hidManager,
            {(context, result, sender, device) in

                // restoring the swift type of the pointer to void
                let caller = unsafeBitCast(context, to: GamepadHIDMonitor.self)

                // must call another function to avoid creating a closure, which is not supported for c functions
                return caller.hidDeviceRemovedCallback(result, sender: sender!, device: device)

            },
            hidContext // reference to self (GamePadMonitor) that can be passed to c functions, essentially a pointer to void, meaning it can point to any type
        )

        // register a callback for gamepad sending input reports
        IOHIDManagerRegisterInputReportCallback(
            hidManager,
            {(context, result, sender, reportType, reportID, reportPointer, reportLength) in

                // restoring the swift type of the pointer to void
                let caller = unsafeBitCast(context, to: GamepadHIDMonitor.self)

                // Put report bytes in a Swift friendly object
                let report = Data(bytes: reportPointer, count: reportLength)

                // must call another function to avoid creating a closure, which is not supported for c functions
                return caller.inputReportCallback(result: result, sender: sender!, reportType: reportType, reportID: reportID, report: report)
            },
            hidContext  // reference to self (GamePadMonitor) that can be passed to c functions, essentially a pointer to void, meaning it can point to any type
        )

        RunLoop.current.run()

    }

    // MARK: HID Manager callbacks

    func hidDeviceAddedCallback(_ result: IOReturn, sender: UnsafeMutableRawPointer, device: IOHIDDevice) {

        // Helpers to read IOHID properties safely
        func getCFProperty(_ key: CFString) -> AnyObject? {
            IOHIDDeviceGetProperty(device, key) as AnyObject?
        }

        func getIntValue(_ key: CFString) -> Int64? {
            guard let any = getCFProperty(key) else { return nil }
            if let num = any as? NSNumber {
                return num.int64Value
            }
            // Some drivers may expose CFString numbers; try parsing
            if let str = any as? String, let parsed = Int64(str) {
                return parsed
            }
            if CFGetTypeID(any) == CFStringGetTypeID() {
                // Bridge CFString to Swift String
                let bridged = any as! CFString
                if let parsed = Int64(bridged as String) {
                    return parsed
                }
            }
            return nil
        }

        func getStringValue(_ key: CFString) -> String? {
            guard let any = getCFProperty(key) else { return nil }
            if let s = any as? String { return s }
            if CFGetTypeID(any) == CFStringGetTypeID() {
                // No conditional downcast warning; we’ve checked the CFTypeID.
                let cfStr = any as! CFString
                return cfStr as String
            }
            return nil
        }

        // Read properties safely
        let locationID = getIntValue(kIOHIDLocationIDKey as CFString)
        let productName = getStringValue(kIOHIDProductKey as CFString)
        let productID = getIntValue(kIOHIDProductIDKey as CFString)
        let vendorName = getStringValue(kIOHIDManufacturerKey as CFString)
        let vendorID = getIntValue(kIOHIDVendorIDKey as CFString)
        let transport = getStringValue(kIOHIDTransportKey as CFString)

        // Log without force-unwrap
        print("locationID: \(locationID.map(String.init) ?? "unknown")")
        print("productName: \(productName ?? "unknown")")
        print("vendorName: \(vendorName ?? "unknown")")
        print("transport: \(transport ?? "unknown")")
        print("vendorID: \(vendorID.map(String.init) ?? "unknown")")
        print("productID: \(productID.map(String.init) ?? "unknown")")

        // We need at least a productID to proceed
        guard let pid = productID else {
            print("HID: Missing productID; skipping device setup.")
            return
        }

        // Use a best-effort transport string
        let transportString = transport ?? "Unknown"

        if self.joyConController == nil {
            self.joyConController = JoyConController(device: device, productID: pid, transport: transportString)
        } else {
            self.joyConController?.setDevice(device: device, productID: pid, transport: transportString)
        }
    }

    func hidDeviceRemovedCallback(_ result: IOReturn, sender: UnsafeMutableRawPointer, device: IOHIDDevice) {
        // You could clear or update state here if you track per-device instances.
    }

    /// gamepad input report callback
    func inputReportCallback(result: IOReturn, sender: UnsafeMutableRawPointer, reportType: IOHIDReportType, reportID: UInt32, report: Data) {
        // Guard against nil controller
        guard let controller = self.joyConController else { return }
        controller.parseReport(report, controllerType: JoyConController.CONTROLLER_ID_JOY_CON_LEFT)
    }

    /// gamepad input valuecallback
    func inputValueCallback(result: IOReturn, sender: UnsafeMutableRawPointer, value: Data) {
        let device = unsafeBitCast(sender, to: IOHIDDevice.self)
        if device == self.joyConController?.leftDevice {
            self.joyConController?.parseReport(value, controllerType: JoyConController.CONTROLLER_ID_JOY_CON_LEFT)
        }
    }

}
