//
//  AppDelegate.swift
//  GamePad
//
//  Created by Marco Luglio on 29/05/20.
//  Copyright © 2020 Marco Luglio. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    var gamePadHIDMonitor: GamepadHIDMonitor!
    var gamePadHIDThread: Thread!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )

        window.center()
        window.setFrameAutosaveName("GamePad")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        // Start service that communicates with controller in separate thread
        self.gamePadHIDMonitor = GamepadHIDMonitor()
        self.gamePadHIDThread = Thread(target: self.gamePadHIDMonitor, selector: #selector(self.gamePadHIDMonitor.setupHidObservers), object: nil)
        self.gamePadHIDThread.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up HID monitoring
        self.gamePadHIDMonitor = nil
        self.gamePadHIDThread = nil
    }
}

struct AppDelegate_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}
