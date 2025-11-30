//
//  JoyConController.swift
//  GamePad
//
//  Created by Marco Luglio on 06/06/20.
//  Copyright © 2020 Marco Luglio. All rights reserved.
//

import Foundation
import SwiftUI

final class JoyConController {

	// MARK: product ids

	static let VENDOR_ID_NINTENDO:Int64 = 0x057E // 1406

	static let CONTROLLER_ID_JOY_CON_LEFT:Int64  = 0x2006 // 8198
	static let CONTROLLER_ID_JOY_CON_RIGHT:Int64 = 0x2007 // 8199
	static let CONTROLLER_ID_SWITCH_PRO:Int64    = 0x2009 // 8201
	static let CONTROLLER_ID_CHARGING_GRIP:Int64 = 0x200e // 8206
	// 0x0306 Wii Remote Controller RVL-003
	// 0x0337 Wii U GameCube Controller Adapter

	// MARK: hid report ids

	static let INPUT_REPORT_ID_SUBCOMMNAD_REPLY:UInt8 = 0x21 // 33 // Reply to hid output report with subcommand
	static let INPUT_REPORT_ID_BUTTONS:UInt8 = 0x3F // 63 // Simple HID mode. Pushes updates with every button press. Thumbstick is 8 directions only
	static let INPUT_REPORT_ID_BUTTONS_GYRO:UInt8 = 0x30 // 48 // Standard full mode. Pushes current state @60Hz
	static let INPUT_REPORT_ID_BUTTONS_GYRO_NFC_IR:UInt8 = 0x31 // 49 // near field communication reader and infra red camera mode. Pushes large packets @60Hz. Has all zeroes for IR/NFC data if a 11 output report with subcmd 03 00/01/02/03 was not sent before.

	static let OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE:UInt8 = 0x01 // 1
	// OUTPUT 0x03 NFC/IR MCU FW Update packet. // I'm not using this here
	static let OUTPUT_REPORT_ID_RUMBLE:UInt8 = 0x10 // 16
	static let OUTPUT_REPORT_ID_NFC_IR:UInt8 = 0x11 // 17 // Request specific data from the NFC/IR MCU. Can also send rumble. Send with subcmd 03 00/01/02/03??

	// MARK: hid output subreport ids

	static let OUTPUT_REPORT_SUB_ID_SET_INPUT_REPORT_ID:UInt8 = 0x03 // 3

	static let OUTPUT_REPORT_SUB_ID_SPI_FLASH_READ:UInt8  = 0x10 // 16
	static let OUTPUT_REPORT_SUB_ID_SPI_FLASH_WRITE:UInt8 = 0x11 // 17

	// static const u8 JC_SUBCMD_RESET_MCU		= 0x20; // 32
	// static const u8 JC_SUBCMD_SET_MCU_CONFIG	= 0x21; // 33

	static let OUTPUT_REPORT_SUB_ID_TOGGLE_IR_NFC:UInt8       = 0x22 // 34 // Takes one argument:	00 Suspend, 01 Resume, 02 Resume for update

	static let OUTPUT_REPORT_SUB_ID_SET_PLAYER_LIGHTS:UInt8   = 0x30 // 48
	static let OUTPUT_REPORT_SUB_ID_GET_PLAYER_LIGHTS:UInt8   = 0x31 // 49
	static let OUTPUT_REPORT_SUB_ID_SET_HOME_LIGHT:UInt8      = 0x38 // 56

	static let OUTPUT_REPORT_SUB_ID_TOGGLE_IMU:UInt8          = 0x40 // 64
	static let OUTPUT_REPORT_SUB_ID_IMU_SETTINGS:UInt8        = 0x41 // 65
	// 0x42 is write to IMU registers, 0x43 is read from IMU registers. But to read/write calibration data we use the SPI subcommands 0x10 and 0x11
	// static const u8 JC_SUBCMD_WRITE_IMU_REG		= 0x42; // 66
	// static const u8 JC_SUBCMD_READ_IMU_REG		= 0x43; // 67

	static let OUTPUT_REPORT_SUB_ID_TOGGLE_VIBRATION:UInt8    = 0x48 // 72

	static let OUTPUT_REPORT_SUB_ID_BATTERY_VOLTAGE:UInt8     = 0x50 // 80

	// MARK: spi calibration data addresses

	static let IMU_USER_CALIBRATION_FLAG_SPI_ADDRESS:UInt16   = 0x8026; // size 2?
	static let IMU_USER_CALIBRATION_VALUES_SPI_ADDRESS:UInt16 = 0x8028; // size 12?
	static let IMU_FACTORY_CALIBRATION_SPI_ADDRESS:UInt16     = 0x6020; // size 12

	static let LEFT_STICK_USER_CALIBRATION_FLAG_SPI_ADDRESS:UInt16   = 0x8010; // size 2?
	static let LEFT_STICK_USER_CALIBRATION_VALUES_SPI_ADDRESS:UInt16 = 0x8012; // size 6?
	static let LEFT_STICK_FACTORY_CALIBRATION_SPI_ADDRESS:UInt16     = 0x603D; // size 6

	static let RIGHT_STICK_USER_CALIBRATION_FLAG_SPI_ADDRESS:UInt16   = 0x801B; // size 2?
	static let RIGHT_STICK_USER_CALIBRATION_VALUES_SPI_ADDRESS:UInt16 = 0x801D; // size 6
	static let RIGHT_STICK_FACTORY_CALIBRATION_SPI_ADDRESS:UInt16     = 0x6046; // size 6

	static let MAX_STICK = 4096 // 2¹² or 2 ^ 12

	static var outputReportIterator:UInt8 = 0

	static var nextId:UInt8 = 0

	// TODO separate these fields into left and right joy-cons?

	var id:UInt8 = 0

	var productID:Int64 = 0
	var transport:String = ""

	var isBluetooth = false

	// MARK: - left joy-con

	var leftDevice:IOHIDDevice? = nil

	/// contains dpad and left side buttons
	var leftMainButtons:UInt8 = 0
	var previousLeftMainButtons:UInt8 = 0

	var directionalPad:UInt8 = 0
	var previousDirectionalPad:UInt8 = 0

	var upButton = false
	var previousUpButton = false
	var rightButton = false
	var previousRightButton = false
	var downButton = false
	var previousDownButton = false
	var leftButton = false
	var previousLeftButton = false

	// TODO The S* buttons can be the equivalent of the Xbox Elite back paddles

	/// SL button on left joy-con
	var leftSideTopButton = false
	var previousLeftSideTopButton = false

	/// SR on left joy-con
	var leftSideBottomButton = false
	var previousLeftSideBottomButton = false

	/// contains left shoulder, left trigger, minus, capture and stick buttons
	var leftSecondaryButtons:UInt8 = 0
	var previousLeftSecondaryButtons:UInt8 = 0

	// shoulder buttons
	var leftShoulderButton = false
	var previousLeftShoulderButton = false
	var leftTriggerButton = false
	var previousLeftTriggerButton = false

	// other buttons

	var minusButton = false
	var previousMinusButton = false

	var captureButton = false
	var previousCaptureButton = false

	// analog buttons (thumbstick only for joy-cons)
	// notice that the simpified report only gives us 8 directions, not analog data

	var leftStickButton = false
	var previousLeftStickButton = false

	// 8 direction stick data
	var leftStick:UInt8 = 0
	var previousLeftStick:UInt8 = 0

	// analog stick data
	var leftStickX:UInt16 = 0
	var previousLeftStickX:UInt16 = 0
	var leftStickY:UInt16 = 0
	var previousLeftStickY:UInt16 = 0

	// inertial measurement unit (imu)

	var leftGyroPitch:Int32 = 0
	var previousLeftGyroPitch:Int32 = 0
	var leftGyroYaw:Int32 = 0
	var previousLeftGyroYaw:Int32 = 0
	var leftGyroRoll:Int32 = 0
	var previousLeftGyroRoll:Int32 = 0

	var leftAccelX:Int32 = 0
	var previousLeftAccelX:Int32 = 0
	var leftAccelY:Int32 = 0
	var previousLeftAccelY:Int32 = 0
	var leftAccelZ:Int32 = 0
	var previousLeftAccelZ:Int32 = 0

	// battery
	//var cableConnected = false
	var batteryLeftCharging = false
	var batteryLeftLevel:UInt16 = 0
	var previousBatteryLeftLevel:UInt16 = 0

	// misc

	// MARK: - right joy-con

	var rightDevice:IOHIDDevice? = nil

	/// contains dpad and left side buttons
	var rightMainButtons:UInt8 = 0
	var previousRightMainButtons:UInt8 = 0

	var faceButtons:UInt8 = 0
	var previousFaceButtons:UInt8 = 0

	var xButton = false
	var previousXButton = false
	var aButton = false
	var previousAButton = false
	var bButton = false
	var previousBButton = false
	var yButton = false
	var previousYButton = false

	/// SR button on right joy-con
	var rightSideTopButton = false
	var previousRightSideTopButton = false

	/// SL on right joy-con
	var rightSideBottomButton = false
	var previousRightSideBottomButton = false

	/// contains left shoulder, left trigger, minus, capture and stick buttons
	var rightSecondaryButtons:UInt8 = 0
	var previousRightSecondaryButtons:UInt8 = 0

	// shoulder buttons
	var rightShoulderButton = false
	var previousRightShoulderButton = false
	var rightTriggerButton = false
	var previousRightTriggerButton = false

	// other buttons

	var plusButton = false
	var previousPlusButton = false

	var homeButton = false
	var previousHomeButton = false

	// analog buttons (thumbstick only for joy-cons)
	// notice that the simpified report only gives us 8 directions, not analog data

	var rightStickButton = false
	var previousRightStickButton = false

	// 8 direction stick data
	var rightStick:UInt8 = 0
	var previousRightStick:UInt8 = 0

	// analog stick data
	var rightStickX:UInt16 = 0
	var previousRightStickX:UInt16 = 0
	var rightStickY:UInt16 = 0
	var previousRightStickY:UInt16 = 0

	// inertial measurement unit (imu)

	var rightGyroPitch:Int32 = 0
	var previousRightGyroPitch:Int32 = 0
	var rightGyroYaw:Int32 = 0
	var previousRightGyroYaw:Int32 = 0
	var rightGyroRoll:Int32 = 0
	var previousRightGyroRoll:Int32 = 0

	var rightAccelX:Int32 = 0
	var previousRightAccelX:Int32 = 0
	var rightAccelY:Int32 = 0
	var previousRightAccelY:Int32 = 0
	var rightAccelZ:Int32 = 0
	var previousRightAccelZ:Int32 = 0

	// battery
	var batteryRightCharging = false
	var batteryRightLevel:UInt16 = 0
	var previousBatteryRightLevel:UInt16 = 0

	// TODO
	//var cableConnected = false

	// MARK: - methods

	init(device:IOHIDDevice, productID:Int64, transport:String/*, enableIMUReport:Bool*/) {

		self.id = JoyConController.nextId
		JoyConController.nextId = JoyConController.nextId + 1

		self.setDevice(device:device, productID:productID, transport:transport)

		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(self.changeRumble),
				name: JoyConChangeRumbleNotification.Name,
				object: nil
			)

		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(self.setLed),
				name: JoyConChangeLedNotification.Name,
				object: nil
			)
	}

	func setDevice(device:IOHIDDevice, productID:Int64, transport:String/*, enableIMUReport:Bool*/) {
		self.transport = transport
		if self.transport == "Bluetooth" {
			self.isBluetooth = true
		}

		self.productID = productID
        self.leftDevice = device
        IOHIDDeviceOpen(self.leftDevice!, IOOptionBits(kIOHIDOptionsTypeNone)) // or kIOHIDManagerOptionUsePersistentProperties
        initialize()
	}
    
    func stopRumble()
    {
        let cmd_setRumble : [UInt8] = [ 0x10, JoyConController.outputReportIterator,
                                        0x00, 0x01, 0x40, 0x40,
                                        0x00, 0x01, 0x40, 0x40 ]
        print("Ran set rumble command: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_setRumble)) \(JoyConController.outputReportIterator)")
        usleep(100000)
    }
    
    func startRumbleLeft()
    {
        let cmd_setRumble : [UInt8] = [ 0x10, JoyConController.outputReportIterator,
                                        0x00, 0x10, 0x40, 0x40,
                                        0x00, 0x01, 0x40, 0x40 ]
        print("Ran set rumble command: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_setRumble)) \(JoyConController.outputReportIterator)")
        usleep(100000)
    }
    
    func startRumbleRight()
    {
        let cmd_setRumble : [UInt8] = [ 0x10, JoyConController.outputReportIterator,
                                        0x00, 0x01, 0x40, 0x40,
                                        0x00, 0x10, 0x40, 0x40 ]
        print("Ran set rumble command: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_setRumble)) \(JoyConController.outputReportIterator)")
        usleep(100000)
    }
    
    func cmd00()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x00,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd00: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd01()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x01,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x10, 0xE0, 0x60, 0x00, 0x00, 0x06, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd01: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd02()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x02,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x40, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd02: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd03()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x03,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x41, 0x03, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd03: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd04()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x04,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x10, 0x20, 0x60, 0x00, 0x00, 0x18, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd04: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd05()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x05,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x10, 0x80, 0x60, 0x00, 0x00, 0x06, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd05: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd06()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x06,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x10, 0x3D, 0x60, 0x00, 0x00, 0x12, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd06: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func cmd07()
    {
        let cmd_toggleIMU : [UInt8] = [ 0x01, 0x07,
                                        0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40,
                                        0x48, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        print("cmd07: \(self.arbCommand(device: self.leftDevice!, buffer: cmd_toggleIMU)) \(JoyConController.outputReportIterator)");
        usleep(10000)
    }
    
    func initialize()
    {
        // PUT CONTROLLER INTO GYRO MODE
        cmd00()
        cmd01()
        cmd02()
        cmd03()
        cmd04()
        cmd05()
        cmd06()
        cmd07()
    }

	/// Gets called by GamePadMonitor
	func parseReport(_ report:Data, controllerType:Int64) {

		// report[0] // the report type

		let bluetoothOffset = self.isBluetooth ? 0 : 10
        
        //print(report as NSData)
        
		if controllerType == JoyConController.CONTROLLER_ID_JOY_CON_LEFT {

			// MARK: left joycon input report

			if report[0] == JoyConController.INPUT_REPORT_ID_BUTTONS {

				// MARK: left joycon simple input report

				// MARK: left digital buttons

				self.leftMainButtons = report[1]
				// self.batteryLeftLevel = UInt16((leftMainButtons & 0b1111_0000) >> 4) // FIXME I don't think this is accurate
				self.directionalPad = leftMainButtons & 0b0000_1111
                self.yButton = self.directionalPad & 0b0000_0100 == 0b0000_0100
                self.xButton = self.directionalPad & 0b0000_1000 == 0b0000_1000
                self.aButton = self.directionalPad & 0b0000_0010 == 0b0000_0010
                self.bButton = self.directionalPad & 0b0000_0001 == 0b0000_0001
                
                self.directionalPad = leftMainButtons & 0b1111_0000
                self.leftShoulderButton = self.directionalPad & 0b0001_0000 == 0b0001_0000
                self.leftTriggerButton = self.directionalPad & 0b0100_0000 == 0b0100_0000
                self.rightShoulderButton = self.directionalPad & 0b0010_0000 == 0b0010_0000
                self.rightTriggerButton = self.directionalPad & 0b1000_0000 == 0b1000_0000
                
                
                self.directionalPad = report[3]
                self.directionalPad = self.directionalPad & 0b0000_1111
                switch(self.directionalPad)
                {
                    case 0b0000_0000:
                        self.upButton = true
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = false
                        break
                    case 0b0000_0001:
                        self.upButton = true
                        self.rightButton = true
                        self.downButton = false
                        self.leftButton = false
                        break
                    case 0b0000_0010:
                        self.upButton = false
                        self.rightButton = true
                        self.downButton = false
                        self.leftButton = false
                        break
                    case 0b0000_0011:
                        self.upButton = false
                        self.rightButton = true
                        self.downButton = true
                        self.leftButton = false
                        break
                    case 0b0000_0100:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = true
                        self.leftButton = false
                        break
                    case 0b0000_0101:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = true
                        self.leftButton = true
                        break
                    case 0b0000_0110:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = true
                        break
                    case 0b0000_0111:
                        self.upButton = true
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = true
                        break
                    default:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = false
                        break
                }

				self.leftSecondaryButtons = report[2]
				self.minusButton        = leftSecondaryButtons & 0b0000_1111 == 0b0000_0001
                self.plusButton         = leftSecondaryButtons & 0b0000_1111 == 0b0000_0010
                self.leftStickButton    = leftSecondaryButtons & 0b0000_1111 == 0b0000_0100
                self.rightStickButton   = leftSecondaryButtons & 0b0000_1111 == 0b0000_1000
				self.captureButton      = leftSecondaryButtons & 0b1111_0000 == 0b0010_0000
                self.homeButton         = leftSecondaryButtons & 0b1111_0000 == 0b0001_0000
                
				if leftMainButtons != self.previousLeftMainButtons
                    || leftSecondaryButtons != self.previousLeftSecondaryButtons
                    || directionalPad != self.previousDirectionalPad
				{

					DispatchQueue.main.async {
						NotificationCenter.default.post(
							name: GamepadButtonChangedNotification.Name,
							object: GamepadButtonChangedNotification(
								leftTriggerButton: self.leftTriggerButton,
								leftShoulderButton: self.leftShoulderButton,
								minusButton: self.minusButton,
								leftSideTopButton: self.leftSideTopButton,
								leftSideBottomButton: self.leftSideBottomButton,
								upButton: self.upButton,
								rightButton: self.rightButton,
								downButton: self.downButton,
								leftButton: self.leftButton,
								socialButton: self.captureButton,
								leftStickButton: self.leftStickButton,
								trackPadButton: false,
								centralButton: false,
								rightStickButton: self.rightStickButton,
								rightAuxiliaryButton: self.homeButton,
								faceNorthButton: self.xButton,
								faceEastButton: self.aButton,
								faceSouthButton: self.bButton,
								faceWestButton: self.yButton,
								rightSideBottomButton: self.rightSideBottomButton,
								rightSideTopButton: self.rightSideTopButton,
								plusButton: self.plusButton,
								rightShoulderButton: self.rightShoulderButton,
								rightTriggerButton: self.rightTriggerButton
							)
						)
					}

					self.previousLeftMainButtons = self.leftMainButtons

					self.previousDirectionalPad = self.directionalPad

					self.previousUpButton = self.upButton
					self.previousRightButton = self.rightButton
					self.previousDownButton = self.downButton
					self.previousLeftButton = self.leftButton
                    
                    self.previousYButton = self.yButton
                    self.previousXButton = self.xButton
                    self.previousAButton = self.aButton
                    self.previousBButton = self.bButton

					self.previousLeftSideTopButton = self.leftSideTopButton
					self.previousLeftSideBottomButton = self.leftSideBottomButton

					self.previousLeftSecondaryButtons = self.leftSecondaryButtons

					self.previousLeftShoulderButton = self.leftShoulderButton
					self.previousLeftTriggerButton = self.leftTriggerButton
                    self.previousRightShoulderButton = self.rightShoulderButton
                    self.previousRightTriggerButton = self.rightTriggerButton

					self.previousMinusButton = self.minusButton
					self.previousCaptureButton = self.captureButton
                    self.previousPlusButton = self.plusButton
                    self.previousHomeButton = self.homeButton

					self.previousLeftStickButton = self.leftStickButton
                    self.previousRightStickButton = self.rightStickButton
				}
                
                self.leftStickX = UInt16(report[5]) << 8 | UInt16(report[4])
                self.leftStickY = UInt16(report[7]) << 8 | UInt16(report[6])
                self.rightStickX = UInt16(report[9]) << 8 | UInt16(report[8])
                self.rightStickY = UInt16(report[11]) << 8 | UInt16(report[10])

				if self.previousLeftStickX != self.leftStickX
					|| self.previousLeftStickY != self.leftStickY
                    || self.previousRightStickY != self.rightStickY
                    || self.previousRightStickY != self.rightStickY
				{
					DispatchQueue.main.async {
						NotificationCenter.default.post(
							name: GamepadAnalogChangedNotification.Name,
							object: GamepadAnalogChangedNotification(
								leftStickX: self.leftStickX,
								leftStickY: self.leftStickY,
								rightStickX: self.rightStickX,
								rightStickY: self.rightStickY,
								stickMax: 0xffff,
								leftTrigger: self.leftTriggerButton ? UInt16(UInt8.max) : 0,
								rightTrigger: self.rightTriggerButton ? UInt16(UInt8.max) : 0,
								triggerMax: UInt16(UInt8.max)
							)
						)
					}
                    
                    self.previousLeftStickX = self.leftStickX
                    self.previousLeftStickY = self.leftStickY
                    self.previousRightStickX = self.rightStickX
                    self.previousRightStickY = self.rightStickY
				}
			} else if report[0] == JoyConController.INPUT_REPORT_ID_BUTTONS_GYRO {
                self.leftMainButtons = report[3]
                self.directionalPad = leftMainButtons & 0b0000_1111
                self.yButton = self.directionalPad & 0b0000_0001 == 0b0000_0001
                self.xButton = self.directionalPad & 0b0000_0010 == 0b0000_0010
                self.aButton = self.directionalPad & 0b0000_1000 == 0b0000_1000
                self.bButton = self.directionalPad & 0b0000_0100 == 0b0000_0100
                
                self.directionalPad = leftMainButtons & 0b1111_0000
                self.rightShoulderButton = self.directionalPad & 0b0100_0000 == 0b0100_0000
                self.rightTriggerButton = self.directionalPad & 0b1000_0000 == 0b1000_0000
                 
                switch(report[5] & 0b0000_1111)
                {
                    case 0b0000_0010:
                        self.upButton = true
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = false
                        break
                    case 0b0000_0110:
                        self.upButton = true
                        self.rightButton = true
                        self.downButton = false
                        self.leftButton = false
                        break
                    case 0b0000_0100:
                        self.upButton = false
                        self.rightButton = true
                        self.downButton = false
                        self.leftButton = false
                        break
                    case 0b0000_0101:
                        self.upButton = false
                        self.rightButton = true
                        self.downButton = true
                        self.leftButton = false
                        break
                    case 0b0000_0001:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = true
                        self.leftButton = false
                        break
                    case 0b0000_1001:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = true
                        self.leftButton = true
                        break
                    case 0b0000_1000:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = true
                        break
                    case 0b0000_1010:
                        self.upButton = true
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = true
                        break
                    default:
                        self.upButton = false
                        self.rightButton = false
                        self.downButton = false
                        self.leftButton = false
                        break
                }
                
                self.leftShoulderButton = report[5] & 0b0100_0000 == 0b0100_0000
                self.leftTriggerButton = report[5] & 0b1000_0000 == 0b1000_0000
                self.directionalPad = report[5]

                self.leftSecondaryButtons = report[4]
                self.minusButton        = leftSecondaryButtons & 0b0000_1111 == 0b0000_0001
                self.plusButton         = leftSecondaryButtons & 0b0000_1111 == 0b0000_0010
                self.leftStickButton    = leftSecondaryButtons & 0b0000_1111 == 0b0000_1000
                self.rightStickButton   = leftSecondaryButtons & 0b0000_1111 == 0b0000_0100
                self.captureButton      = leftSecondaryButtons & 0b1111_0000 == 0b0010_0000
                self.homeButton         = leftSecondaryButtons & 0b1111_0000 == 0b0001_0000
                
                if leftMainButtons != self.previousLeftMainButtons
                    || leftSecondaryButtons != self.previousLeftSecondaryButtons
                    || directionalPad != self.previousDirectionalPad
                {

                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: GamepadButtonChangedNotification.Name,
                            object: GamepadButtonChangedNotification(
                                leftTriggerButton: self.leftTriggerButton,
                                leftShoulderButton: self.leftShoulderButton,
                                minusButton: self.minusButton,
                                leftSideTopButton: self.leftSideTopButton,
                                leftSideBottomButton: self.leftSideBottomButton,
                                upButton: self.upButton,
                                rightButton: self.rightButton,
                                downButton: self.downButton,
                                leftButton: self.leftButton,
                                socialButton: self.captureButton,
                                leftStickButton: self.leftStickButton,
                                trackPadButton: false,
                                centralButton: false,
                                rightStickButton: self.rightStickButton,
                                rightAuxiliaryButton: self.homeButton,
                                faceNorthButton: self.xButton,
                                faceEastButton: self.aButton,
                                faceSouthButton: self.bButton,
                                faceWestButton: self.yButton,
                                rightSideBottomButton: self.rightSideBottomButton,
                                rightSideTopButton: self.rightSideTopButton,
                                plusButton: self.plusButton,
                                rightShoulderButton: self.rightShoulderButton,
                                rightTriggerButton: self.rightTriggerButton
                            )
                        )
                    }

                    self.previousLeftMainButtons = self.leftMainButtons

                    self.previousDirectionalPad = self.directionalPad

                    self.previousUpButton = self.upButton
                    self.previousRightButton = self.rightButton
                    self.previousDownButton = self.downButton
                    self.previousLeftButton = self.leftButton
                    
                    self.previousYButton = self.yButton
                    self.previousXButton = self.xButton
                    self.previousAButton = self.aButton
                    self.previousBButton = self.bButton

                    self.previousLeftSideTopButton = self.leftSideTopButton
                    self.previousLeftSideBottomButton = self.leftSideBottomButton

                    self.previousLeftSecondaryButtons = self.leftSecondaryButtons

                    self.previousLeftShoulderButton = self.leftShoulderButton
                    self.previousLeftTriggerButton = self.leftTriggerButton
                    self.previousRightShoulderButton = self.rightShoulderButton
                    self.previousRightTriggerButton = self.rightTriggerButton

                    self.previousMinusButton = self.minusButton
                    self.previousCaptureButton = self.captureButton
                    self.previousPlusButton = self.plusButton
                    self.previousHomeButton = self.homeButton

                    self.previousLeftStickButton = self.leftStickButton
                    self.previousRightStickButton = self.rightStickButton
                }
                
                self.leftStickX = UInt16(report[7] & 0b0000_1111) << 8 | UInt16(report[6])
                self.leftStickY = UInt16(0xfff) - (UInt16(report[8]) << 4 | UInt16(report[7] & 0b1111_0000) >> 4)
                self.rightStickX = UInt16(report[10] & 0b0000_1111) << 8 | UInt16(report[9])
                self.rightStickY = UInt16(0xfff) - (UInt16(report[11]) << 4 | UInt16(report[10] & 0b1111_0000) >> 4)

                if self.previousLeftStickX != self.leftStickX
                    || self.previousLeftStickY != self.leftStickY
                    || self.previousRightStickY != self.rightStickY
                    || self.previousRightStickY != self.rightStickY
                {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: GamepadAnalogChangedNotification.Name,
                            object: GamepadAnalogChangedNotification(
                                leftStickX: self.leftStickX,
                                leftStickY: self.leftStickY,
                                rightStickX: self.rightStickX,
                                rightStickY: self.rightStickY,
                                stickMax: 0x0fff,
                                leftTrigger: self.leftTriggerButton ? UInt16(UInt8.max) : 0,
                                rightTrigger: self.rightTriggerButton ? UInt16(UInt8.max) : 0,
                                triggerMax: UInt16(UInt8.max)
                            )
                        )
                    }
                    
                    self.previousLeftStickX = self.leftStickX
                    self.previousLeftStickY = self.leftStickY
                    self.previousRightStickX = self.rightStickX
                    self.previousRightStickY = self.rightStickY
                }
                
				// TODO x, y, z, pitch, yaw, and roll will depend upon the joy-con being used vertically in pair, or horizontally as standalone, debug this later

				// The controller sends the sensor data 3 times with a little bit different values
				// report IDs x30, x31, x32, x33
				// 6-Axis data. 3 frames of 2 groups of 3 Int16LE each. Group is Acc followed by Gyro.
				// 13-21 group 1
				// 25-36 group 2
				// 37-48 group 3

				// here I'm just getting 1 sample, maybe I should average the values? Or send a notification for each?

				// ?? accelerometer data is in m/s²
				self.leftAccelX = Int32(Int16(report[14 + bluetoothOffset]) << 8 | Int16(report[13 + bluetoothOffset])) // TODO calibrate
				self.leftAccelY = Int32(Int16(report[16 + bluetoothOffset]) << 8 | Int16(report[15 + bluetoothOffset])) // TODO calibrate
				self.leftAccelZ = Int32(Int16(report[18 + bluetoothOffset]) << 8 | Int16(report[17 + bluetoothOffset])) // TODO calibrate

				// ?? gyroscope data is in rad/s
				self.leftGyroPitch = Int32(Int16(report[20 + bluetoothOffset]) << 8 | Int16(report[19 + bluetoothOffset])) // TODO calibrate
				self.leftGyroYaw   = Int32(Int16(report[22 + bluetoothOffset]) << 8 | Int16(report[21 + bluetoothOffset])) // TODO calibrate
				self.leftGyroRoll  = Int32(Int16(report[24 + bluetoothOffset]) << 8 | Int16(report[23 + bluetoothOffset])) // TODO calibrate

				if self.previousLeftGyroPitch != self.leftGyroPitch
					|| self.previousLeftGyroYaw != self.leftGyroYaw
					|| self.previousLeftGyroRoll != self.leftGyroRoll
					|| self.previousLeftAccelX != self.leftAccelX
					|| self.previousLeftAccelY != self.leftAccelY
					|| self.previousLeftAccelZ != self.leftAccelZ
				{

					self.previousLeftGyroPitch = self.leftGyroPitch
					self.previousLeftGyroYaw   = self.leftGyroYaw
					self.previousLeftGyroRoll  = self.leftGyroRoll

					self.previousLeftAccelX = self.leftAccelX
					self.previousLeftAccelY = self.leftAccelY
					self.previousLeftAccelZ = self.leftAccelZ

					DispatchQueue.main.async {
						NotificationCenter.default.post(
							name: GamepadIMUChangedNotification.Name,
							object: GamepadIMUChangedNotification(
								gyroPitch: self.leftGyroPitch,
								gyroYaw:   self.leftGyroYaw,
								gyroRoll:  self.leftGyroRoll,
								accelX: self.leftAccelX,
								accelY: self.leftAccelY,
								accelZ: self.leftAccelZ
							)
						)
					}
				}
			} else if report[0] == JoyConController.INPUT_REPORT_ID_SUBCOMMNAD_REPLY {
                //print("subcommand: ")
                //print(report as NSData)

				/*
				spi serial pehipheral interface
				Subcommand 0x10: SPI flash read

				Little-endian int32 address, int8 size, max size is x1D. Replies with x9010 ack and echoes the request info, followed by size bytes of data.

				Request:
				[01 .. .. .. .. .. .. .. .. .. 10 80 60 00 00 18]
											   ^ subcommand
												  ^~~~~~~~~~~ address x6080
															  ^ length = 0x18 bytes
				Response: INPUT 21
				[xx .E .. .. .. .. .. .. .. .. .. .. 0. 90 80 60 00 00 18 .. .. .. ....]
														^ subcommand reply
															  ^~~~~~~~~~~ address
																	   ^ length = 0x18 bytes
																		  ^~~~~ data

				Subcommand 0x11: SPI flash Write

				Little-endian int32 address, int8 size. Max size x1D data to write. Replies with x8011 ack and a uint8 status. x00 = success, x01 = write protected.
				*/

                /*
				if report[13] & 0b1000_0000 != 0b1000_0000 {
					print("output report not acknowledged")
					return
				}

				if report[13] == 0x90 && report[14] == 0x10 {

					print("read spi report")

					let spiAddress = UInt16(report[15]) | (UInt16(report[16]) << 8) // | (UInt32(report[17]) << 16) | (UInt32(report[18]) << 24) // none of the addresses I use exceeed 16 bits

					switch spiAddress {

					case JoyConController.IMU_USER_CALIBRATION_FLAG_SPI_ADDRESS:
						// TODO check flag and request user or factory report
						break

					case JoyConController.IMU_USER_CALIBRATION_VALUES_SPI_ADDRESS:
						break

					case JoyConController.IMU_FACTORY_CALIBRATION_SPI_ADDRESS:
						self.parseIMUCalibration(report: report)
						break

					case JoyConController.LEFT_STICK_USER_CALIBRATION_FLAG_SPI_ADDRESS:
						// TODO check flag and request user or factory report
						break

					case JoyConController.LEFT_STICK_USER_CALIBRATION_VALUES_SPI_ADDRESS:
						break

					case JoyConController.LEFT_STICK_FACTORY_CALIBRATION_SPI_ADDRESS:
						self.parseStickCalibration(report: report)
						break

					case JoyConController.RIGHT_STICK_USER_CALIBRATION_FLAG_SPI_ADDRESS:
						// TODO check flag and request user or factory report
						break

					case JoyConController.RIGHT_STICK_USER_CALIBRATION_VALUES_SPI_ADDRESS:
						break

					case JoyConController.RIGHT_STICK_FACTORY_CALIBRATION_SPI_ADDRESS:
						self.parseStickCalibration(report: report)
						break

					default:
						print("Unknown 0x21 reply report")
						print("report[13]: 0x\(String(report[13], radix: 16)) \(report[13])")
						print("report[14]: 0x\(String(report[14], radix: 16)) \(report[14])")
						return

					}

				} else if report[13] == 0xD0 && report[14] == 0x50 {

					self.batteryLeftLevel = UInt16(report[16]) << 8 | UInt16(report[15]) // Internally, the values come from 1000mV - 1800mV regulated voltage samples, that are translated to 1320-1680 values.
					print("\nleft battery: \(self.batteryLeftLevel)")

					if self.previousBatteryLeftLevel != self.batteryLeftLevel {

						self.previousBatteryLeftLevel = self.batteryLeftLevel

						let battery = (Float64(self.batteryLeftLevel) * 256.0) / 360

						DispatchQueue.main.async {
							NotificationCenter.default.post(
								name: GamepadBatteryChangedNotification.Name,
								object: GamepadBatteryChangedNotification(
									battery: UInt8(battery),
									batteryMin: 0,
									batteryMax: 255,
									isConnected: false, // TODO
									isCharging: false // TODO
								)
							)
						}

					}

					return

				}

				print("\nreport 0x21 size: \(report.count)")

				// address, compare with what I sent
				print("report[1]: 0x\(String(report[1], radix: 16)) \(report[1])")
				print("report[2]: 0x\(String(report[2], radix: 16)) \(report[2])")
				print("report[3]: 0x\(String(report[3], radix: 16)) \(report[3])")
				print("report[4]: 0x\(String(report[4], radix: 16)) \(report[4])")

				print("report[5]: 0x\(String(report[5], radix: 16)) \(report[5])") // zero for left imu factory

				// data
				print("report[6]: 0x\(String(report[6], radix: 16)) \(report[6])")
				print("report[7]: 0x\(String(report[7], radix: 16)) \(report[7])")
				print("report[8]: 0x\(String(report[8], radix: 16)) \(report[8])")
				print("report[9]: 0x\(String(report[9], radix: 16)) \(report[9])") // zero

				// all zeroes for left imu factory
				print("report[10]: 0x\(String(report[10], radix: 16)) \(report[10])")
				print("report[11]: 0x\(String(report[11], radix: 16)) \(report[11])")

				// 13 would be the subcommand reply, then 32 bits address, then length of data

				// data
				print("report[12]: 0x\(String(report[12], radix: 16)) \(report[12])")
				print("report[13]: 0x\(String(report[13], radix: 16)) \(report[13])")
				print("report[14]: 0x\(String(report[14], radix: 16)) \(report[14])")

				// all zeroes for left imu factory
				print("report[15]: 0x\(String(report[15], radix: 16)) \(report[15])")
				print("report[16]: 0x\(String(report[16], radix: 16)) \(report[16])")
				print("report[17]: 0x\(String(report[17], radix: 16)) \(report[17])")
				print("report[18]: 0x\(String(report[18], radix: 16)) \(report[18])")
				print("report[19]: 0x\(String(report[19], radix: 16)) \(report[19])")

				print("report[20]: 0x\(String(report[20], radix: 16)) \(report[20])")
				print("report[21]: 0x\(String(report[21], radix: 16)) \(report[21])")
				print("report[22]: 0x\(String(report[22], radix: 16)) \(report[22])")
				print("report[23]: 0x\(String(report[23], radix: 16)) \(report[23])")
				print("report[24]: 0x\(String(report[24], radix: 16)) \(report[24])")
				print("report[25]: 0x\(String(report[25], radix: 16)) \(report[25])")
				print("report[26]: 0x\(String(report[26], radix: 16)) \(report[26])")
				print("report[27]: 0x\(String(report[27], radix: 16)) \(report[27])")
				print("report[28]: 0x\(String(report[28], radix: 16)) \(report[28])")
				print("report[29]: 0x\(String(report[29], radix: 16)) \(report[29])")

				print("report[30]: 0x\(String(report[30], radix: 16)) \(report[30])")
				print("report[31]: 0x\(String(report[31], radix: 16)) \(report[31])")
				print("report[32]: 0x\(String(report[32], radix: 16)) \(report[32])")
				print("report[33]: 0x\(String(report[33], radix: 16)) \(report[33])")
				print("report[34]: 0x\(String(report[34], radix: 16)) \(report[34])")
				print("report[35]: 0x\(String(report[35], radix: 16)) \(report[35])")
				print("report[36]: 0x\(String(report[36], radix: 16)) \(report[36])")
				print("report[37]: 0x\(String(report[37], radix: 16)) \(report[37])")
				print("report[38]: 0x\(String(report[38], radix: 16)) \(report[38])")
				print("report[39]: 0x\(String(report[39], radix: 16)) \(report[39])")

				print("report[40]: 0x\(String(report[40], radix: 16)) \(report[40])")
				print("report[41]: 0x\(String(report[41], radix: 16)) \(report[41])")
				print("report[42]: 0x\(String(report[42], radix: 16)) \(report[42])")
				print("report[43]: 0x\(String(report[43], radix: 16)) \(report[43])")
				print("report[44]: 0x\(String(report[44], radix: 16)) \(report[44])")
				print("report[45]: 0x\(String(report[45], radix: 16)) \(report[45])")
				print("report[46]: 0x\(String(report[46], radix: 16)) \(report[46])")
				print("report[47]: 0x\(String(report[47], radix: 16)) \(report[47])")
				print("report[48]: 0x\(String(report[48], radix: 16)) \(report[48])")
*/
			} else if report.count > 0 {

				// input 21 is a response for spi subcommands apparently, treat that here
				print("unsupported report: \(report[0]) 0x\(String(report[0], radix:16))")

			}
		}
        else
        {
            print("unknown controller type")
        }
	}

	// MARK: - hid output report methods

	@objc func changeRumble(_ notification:Notification) {

		let o = notification.object as! JoyConChangeRumbleNotification

		/*sendRumbleReport(
			leftHeavySlowRumble: o.leftHeavySlowRumble,
			rightLightFastRumble: o.rightLightFastRumble,
			leftTriggerRumble: o.leftTriggerRumble,
			rightTriggerRumble: o.rightTriggerRumble
		)*/

	}

	@objc func setLed(_ notification:Notification) {

		let o = notification.object as! JoyConChangeLedNotification

		/*self.sendReport(
			device: self.leftDevice!, // FIXME
			led1On: o.led1On,
			led2On: o.led2On,
			led3On: o.led3On,
			led4On: o.led4On,
			blinkLed1: o.blinkLed1,
			blinkLed2: o.blinkLed2,
			blinkLed3: o.blinkLed3,
			blinkLed4: o.blinkLed4
			// TODO home led...
		)*/

	}

	func toggleVibration(device:IOHIDDevice, enable:Bool) -> Bool {

		let joyConToggleVibrationReportLength = 49
		var buffer = [UInt8](repeating: 0, count: joyConToggleVibrationReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40

		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x10
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_TOGGLE_VIBRATION

		// sub report type parameter 1
		buffer[11] = enable ? 0x01 : 0x00

		let success = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			Int(buffer[0]), // Report ID
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		if success != kIOReturnSuccess {
			return false
		}

		return true

	}

	func getStickCalibration(device:IOHIDDevice) -> Bool {

		var success = false

		if self.leftDevice != nil {
			// TODO check for user calibration, and then choose between factory and user
			// success = self.readSpiFlash(device:device, startAddress: JoyConController.LEFT_STICK_USER_CALIBRATION_FLAG_SPI_ADDRESS, size: 2) // TODO check size
			// success = self.readSpiFlash(device:device, startAddress: JoyConController.LEFT_STICK_USER_CALIBRATION_VALUES_SPI_ADDRESS, size: 6) // TODO check size
			success = self.readSpiFlash(device:device, startAddress: JoyConController.LEFT_STICK_FACTORY_CALIBRATION_SPI_ADDRESS, size: 6)
		}

		if self.rightDevice != nil {
			// TODO check for user calibration, and then choose between factory and user
			// success = self.readSpiFlash(device:device, startAddress: JoyConController.RIGHT_STICK_USER_CALIBRATION_FLAG_SPI_ADDRESS, size: 2) // TODO check size
			// success = self.readSpiFlash(device:device, startAddress: JoyConController.RIGHT_STICK_USER_CALIBRATION_VALUES_SPI_ADDRESS, size: 6) // TODO check size
			success = self.readSpiFlash(device:device, startAddress: JoyConController.RIGHT_STICK_FACTORY_CALIBRATION_SPI_ADDRESS, size: 6)
		}

		return success

	}

	func parseStickCalibration(report:Data) { // TODO check the best way to tell if this is the left or right calibration data

		// TODO

	}

	// TODO
	func getBattery(device:IOHIDDevice) -> Bool {

		/*
		Subcommand 0x50: Get regulated voltage

		Replies with ACK xD0 x50 and a little-endian uint16. Raises when charging a Joy-Con.
		Internally, the values come from 1000mV - 1800mV regulated voltage samples, that are translated to 1320-1680 values.
		These follow a curve between 3.3V and 4.2V (tested with multimeter). So a 2.5x multiplier can get us the real battery voltage in mV.

		Based on this info, we have the following table:

		Range # 	Range 	Range in mV 	Reported battery
		x0528 - x059F 	1320 - 1439 	3300 - 3599 	2 - Critical
		x05A0 - x05DF 	1440 - 1503 	3600 - 3759 	4 - Low
		x05E0 - x0617 	1504 - 1559 	3760 - 3899 	6 - Medium
		x0618 - x0690 	1560 - 1680 	3900 - 4200 	8 - Full

		Tests showed charging stops at 1680 and the controller turns off at 1320.
		*/

		let joyConBatteryVoltageReportLength = 49
		var buffer = [UInt8](repeating: 0, count: joyConBatteryVoltageReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40

		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x10
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_BATTERY_VOLTAGE

		let toggleSuccess = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			Int(buffer[0]), // Report ID
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		if toggleSuccess != kIOReturnSuccess {
			return false
		}

		return true

	}
    
    func arbCommand(device:IOHIDDevice, buffer:[UInt8]) -> Bool {
        let toggleSuccess = IOHIDDeviceSetReport(
            device,
            kIOHIDReportTypeOutput,
            Int(buffer[0]), // Report ID
            buffer,
            buffer.count
        );
        
        print(buffer.count)

        JoyConController.outputReportIterator = (JoyConController.outputReportIterator + 1) % 0x0F

        if toggleSuccess != kIOReturnSuccess {
            return false
        }
        
        return true
    }
    
    func arbCommandWithCallback(device:IOHIDDevice, buffer:[UInt8]) -> Bool {
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        let hidContext = unsafeBitCast(appDelegate?.gamePadHIDMonitor, to: UnsafeMutableRawPointer.self)
        
        let toggleSuccess = IOHIDDeviceSetReportWithCallback(
            device,
            kIOHIDReportTypeOutput,
            Int(buffer[0]), // Report ID
            buffer,
            buffer.count,
            100,
            {(context, result, sender, reportType, reportID, reportPointer, reportLength) in
                // restoring the swift type of the pointer to void
                let caller = unsafeBitCast(context, to: GamepadHIDMonitor.self)
                // Put report bytes in a Swift friendly object
                let report = Data(bytes:reportPointer, count:reportLength)
                // must call another function to avoid creating a closure, which is not supported for c functions
                return caller.inputReportCallback(result:result, sender:sender!, reportType:reportType, reportID:reportID, report:report)
            },
            hidContext
        );

        JoyConController.outputReportIterator = (JoyConController.outputReportIterator + 1) % 0x0F

        if toggleSuccess != kIOReturnSuccess {
            return false
        }
        
        return true
    }

	// MARK: - imu hid output report methods

	func toggleIMU(device:IOHIDDevice, enable:Bool) -> Bool {

		let joyConToggleIMUReportLength = 12
		var buffer = [UInt8](repeating: 0, count: joyConToggleIMUReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40

		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x01
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_TOGGLE_IMU

		// sub report type parameter 1
		buffer[11] = enable ? 0x01 : 0x00

		let reportId = Int(buffer[0])

		let toggleSuccess = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			reportId,
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		/*
		Enabling IMU if it was previously disabled
		resets your configuration to Acc: 1.66 kHz (high perf), ±8G, 100 Hz Anti-aliasing filter bandwidth
		and Gyro: 208 Hz (high performance), ±2000dps..

		So I'm resetting to my own settings. That are more similar to DualShock 4
		*/

		let settingsSuccess = self.imuSettings(device:device)

		// TODO load calibration data from Serial Peripheral Interface (SPI)

		if toggleSuccess != kIOReturnSuccess && !settingsSuccess {
			return false
		}

		return true

	}

	func imuSettings(device:IOHIDDevice) -> Bool {

		let joyConIMUSettingsReportLength = 49
		var buffer = [UInt8](repeating: 0, count: joyConIMUSettingsReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40

		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x10
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_IMU_SETTINGS

		// gyro sensivity
		// 00 ±250°/s
		// 01 ±500°/s
		// 02 ±1000°/s
		// 03 ±2000°/s (default) same as DualShock4 I believe
		buffer[11] = 0x03

		// accel G range
		// 00 ±8G (default)
		// 01 ±4G
		// 02 ±2G
		// 03 ±16G
		buffer[12] = 0x00//0x02 // 2G

		// gyro sampling frequency??
		// 00 833Hz (high perf)
		// 01 208Hz (high perf, default)
		buffer[13] = 0x00//0x01

		// accel anti-aliasing filter bandwidth
		// 00 200Hz
		// 01 100Hz (default)
		buffer[14] = 0x01

		let reportId = Int(buffer[0])

		let success = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			reportId,
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		if success != kIOReturnSuccess {
			return false
		}

		return true

	}

	func getIMUCalibration(device:IOHIDDevice) -> Bool {

		var success = false
		success = self.readSpiFlash(device:device, startAddress: JoyConController.IMU_FACTORY_CALIBRATION_SPI_ADDRESS, size: 12)

		return success

	}

	func parseIMUCalibration(report:Data) {

	}

	func setInputReportId(device:IOHIDDevice, _ inputReportId:UInt8) -> Bool {

		let joyConSetInputReportReportLength = 49
		var buffer = [UInt8](repeating: 0, count: joyConSetInputReportReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40

		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x10
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_SET_INPUT_REPORT_ID

		// sub report type parameter 1
		buffer[11] = inputReportId

		let reportId = Int(buffer[0])

		let success = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			reportId,
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		if success != kIOReturnSuccess {
			return false
		}

		return true

	}

	func readSpiFlash(device:IOHIDDevice, startAddress:UInt16, size:UInt8) -> Bool {

		if size > 29 {
			print("Unsupported theoretycally. TODO throw error?")
			return false
		}

		let joyConSpiFlashReadReportLength = 49
		var buffer = [UInt8](repeating: 0, count: joyConSpiFlashReadReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40

		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x10
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_SPI_FLASH_READ

		// 4 bytes for an UInt32 address, but none of the values I use exceeed 16 bits
		// Trying to avoid using pointers here to get the bytes...
		buffer[11] = 0 // UInt8(clamping: 0x000000FF & startAddress)
		buffer[12] = 0 // UInt8(clamping: 0x000000FF & (startAddress >> 8))
		buffer[13] = UInt8(clamping: 0x00FF & startAddress) // UInt8(clamping: 0x000000FF & (startAddress >> 16))
		buffer[14] = UInt8(clamping: 0x00FF & (startAddress >> 8)) // UInt8(clamping: 0x000000FF & (startAddress >> 24))

		// 1 byte for an UInt8 size
		buffer[15] = size

		let reportId = Int(buffer[0])

		let success = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			reportId,
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		if success != kIOReturnSuccess {
			return false
		}

		return true
	}

	func sendReport(
		device:IOHIDDevice,
		led1On:Bool = false,
		led2On:Bool = false,
		led3On:Bool = false,
		led4On:Bool = false,
		blinkLed1:Bool = false,
		blinkLed2:Bool = false,
		blinkLed3:Bool = false,
		blinkLed4:Bool = false
		// TODO home led...
	) -> Bool {

		let joyConSetPlayerLightsReportLength = 49
		var buffer = [UInt8](repeating: 0, count: joyConSetPlayerLightsReportLength)

		buffer[0] = JoyConController.OUTPUT_REPORT_ID_RUMBLE_SEND_SUB_TYPE
		buffer[1] = JoyConController.outputReportIterator

		// neutral rumble left
		buffer[2] = 0x00
		buffer[3] = 0x01
		buffer[4] = 0x40
		buffer[5] = 0x40
        
		// neutral rumble right
		buffer[6] = 0x00
		buffer[7] = 0x10
		buffer[8] = 0x40
		buffer[9] = 0x40

		// sub report type or sub command
		buffer[10] = JoyConController.OUTPUT_REPORT_SUB_ID_SET_PLAYER_LIGHTS

		/*
		Subcommand Get player lights
		Replies with ACK xB0 x31 and one byte that uses the same bitfield with x30 subcommand
		The initial LED trail effects is 10110001 (xB1), but it cannot be set via x30. subcommand
		*/

		var leds:UInt8 = 0b0000_0000

		if led1On {
			leds = leds | 0b0000_0001
		}

		if led2On {
			leds = leds | 0b0000_0010
		}

		if led3On {
			leds = leds | 0b0000_0100
		}

		if led4On {
			leds = leds | 0b0000_1000
		}

		// "on" bits override "flash" bits. When on USB, "flash" bits work like "on" bits.

		if blinkLed1 {
			leds = leds | 0b0001_0000
		}
		if blinkLed2 {
			leds = leds | 0b0010_0000
		}
		if blinkLed3 {
			leds = leds | 0b0100_0000
		}
		if blinkLed4 {
			leds = leds | 0b1000_0000
		}

		// sub report type parameter 1
		buffer[11] = leds

		let reportId = Int(buffer[0])

		let success = IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			reportId,
			buffer,
			buffer.count
		);

		JoyConController.outputReportIterator = JoyConController.outputReportIterator &+ 1

		if success != kIOReturnSuccess {
			return false
		}

		return true

	}

}
