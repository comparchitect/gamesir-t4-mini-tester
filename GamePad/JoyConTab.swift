//
//  JoyConTab.swift
//  GamePad
//
//  Created by Marco Luglio on 11/06/21.
//  Copyright © 2021 Marco Luglio. All rights reserved.
//

import SwiftUI

struct JoyConTab: View {

    @ObservedObject var joyCon = JoyConUIModel()
    let appDelegate = NSApplication.shared.delegate as? AppDelegate
    @StateObject private var orientationModel = OrientationModel()

    var body: some View {
        HStack(spacing: 16) {

            // LEFT PANE
            VStack(alignment: .leading, spacing: 12) {

                // Top area: original left/right controls condensed a bit
                HStack(alignment: .top, spacing: 16) {

                    // MARK: JoyCon left
                    VStack(alignment: .center, spacing: 12) {

                        Group {
                            // ZL matches L style/size (90x15 rounded rect)
                            ZStack {
                                Path(
                                    roundedRect: CGRect(x: 0, y: 0, width: 90, height: 15),
                                    cornerRadius: 15
                                )
                                .foregroundColor(self.joyCon.leftTriggerButton ? Color.red : Color.white)
                                .frame(width: 90, height: 15)

                                Text("ZL").foregroundColor(.black)
                            }

                            // L
                            ZStack {
                                Path(
                                    roundedRect: CGRect(x: 0, y: 0, width: 90, height: 15),
                                    cornerRadius: 15
                                )
                                .foregroundColor(self.joyCon.leftShoulderButton ? Color.red : Color.white)
                                .frame(width: 90, height: 15)

                                Text("L").foregroundColor(.black)
                            }

                            Text(self.joyCon.minusButton ? "Pressed" : "-")
                        }

                        HStack {
                            Coords2d(
                                x: CGFloat(self.joyCon.leftStickX),
                                y: CGFloat(self.joyCon.leftStickY),
                                foregroundColor: self.joyCon.leftStickButton ? Color.red : Color.white
                            )
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        }

                        VStack(spacing: 6) {
                            Text(self.joyCon.upButton ? "Pressed" : "Up")
                            HStack {
                                Text(self.joyCon.leftButton ? "Pressed" : "Left")
                                Text(self.joyCon.rightButton ? "Pressed" : "Right")
                            }
                            Text(self.joyCon.downButton ? "Pressed" : "Down")
                        }

                        HStack {
                            Text(self.joyCon.captureButton ? "Pressed" : "Capture")
                        }

                        VStack(spacing: 8) {
                            Button(action: {
                                appDelegate?.gamePadHIDMonitor.joyConController?.startRumbleLeft()
                            }) { Text("Start left rumble") }
                            Button(action: {
                                appDelegate?.gamePadHIDMonitor.joyConController?.stopRumble()
                            }) { Text("Stop rumble") }
                        }
                    }

                    // MARK: JoyCon right
                    VStack(alignment: .center, spacing: 12) {

                        Group {
                            // ZR matches R style/size (90x15 rounded rect)
                            ZStack {
                                Path(
                                    roundedRect: CGRect(x: 0, y: 0, width: 90, height: 15),
                                    cornerRadius: 15
                                )
                                .foregroundColor(self.joyCon.rightTriggerButton ? Color.red : Color.white)
                                .frame(width: 90, height: 15)

                                Text("ZR").foregroundColor(.black)
                            }

                            // R
                            ZStack {
                                Path(
                                    roundedRect: CGRect(x: 0, y: 0, width: 90, height: 15),
                                    cornerRadius: 15
                                )
                                .foregroundColor(self.joyCon.rightShoulderButton ? Color.red : Color.white)
                                .frame(width: 90, height: 15)

                                Text("R").foregroundColor(.black)
                            }

                            Text(self.joyCon.plusButton ? "Pressed" : "+")
                        }

                        VStack(spacing: 6) {
                            Text(self.joyCon.xButton ? "Pressed" : "X")
                            HStack {
                                Text(self.joyCon.yButton ? "Pressed" : "Y")
                                Text(self.joyCon.aButton ? "Pressed" : "A")
                            }
                            Text(self.joyCon.bButton ? "Pressed" : "B")
                        }

                        Coords2d(
                            x: CGFloat(self.joyCon.rightStickX),
                            y: CGFloat(self.joyCon.rightStickY),
                            foregroundColor: self.joyCon.rightStickButton ? Color.red : Color.white
                        )
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                        HStack {
                            Text(self.joyCon.homeButton ? "Pressed" : "Home")
                        }

                        VStack(spacing: 8) {
                            Button(action: {
                                appDelegate?.gamePadHIDMonitor.joyConController?.startRumbleRight()
                            }) { Text("Start right rumble") }
                            Button(action: {
                                appDelegate?.gamePadHIDMonitor.joyConController?.stopRumble()
                            }) { Text("Stop rumble") }
                        }
                    }
                }

                Spacer() // Push the telemetry block to the bottom-left

                // Bottom-left: Gyro/Accel readouts
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gyro pitch: \(self.joyCon.leftGyroPitch)").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Gyro yaw:  \(self.joyCon.leftGyroYaw)").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Gyro roll:  \(self.joyCon.leftGyroRoll)").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Accel x:  \(self.joyCon.leftAccelX)").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Accel y:  \(self.joyCon.leftAccelY)").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Accel z:  \(self.joyCon.leftAccelZ)").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .padding(.bottom, 8)
            }
            .frame(minWidth: 360)

            // RIGHT PANE
            VStack(spacing: 8) {
                // 3D view expands to fill right pane
                Controller3DView(model: orientationModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(8)

                // Calibrate button anchored at the bottom
                Button("Calibrate (Zero)") {
                    orientationModel.calibrate()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 8)
        }
        .padding(12)
    }
}

struct JoyConTab_Previews: PreviewProvider {
    static var previews: some View {
        JoyConTab()
            .frame(width: 1000, height: 600)
    }
}
