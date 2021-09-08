//
//  AppDelegate.swift
//  bose-macos-utility
//
//  Created by Łukasz Zalewski on 23/06/2021.
//

import Cocoa
import IOBluetooth

// TODO: add documentation to each method
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep a reference to the status bar item to keep it alive throughout the whole lifetime of the application
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    var selectDeviceMenu: NSMenu!
    var pairedDevices: [IOBluetoothDevice] = []
    var channel: IOBluetoothRFCOMMChannel?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // We need to setup the status bar first, since we want to add the paired devices to it in the second call
        setupStatusBar()
        setupConnectionToHeadphones()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

// MARK: - Menu app construction methods
extension AppDelegate {
    private func setupStatusBar() {
        // Initalize the menu bar extra
        let statusBar = NSStatusBar.system
        
        let statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        self.statusBarItem = statusBarItem
        // TODO: use the template image, so that the icon is changed when the dark/light mode settings change
        statusBarItem.button?.title = "🎧"
        let statusBarMenu = NSMenu()
        statusBarMenu.showsStateColumn = true
        statusBarMenu.autoenablesItems = false
        self.statusBarMenu = statusBarMenu
        statusBarItem.menu = statusBarMenu
        
        // Add the noise cancellation item
        let noiseCancellationMenu = NSMenuItem()
        noiseCancellationMenu.title = "Noise cancellation"
        statusBarMenu.addItem(noiseCancellationMenu)
        
        // Add the select target device item
        let selectDeviceMenu = NSMenuItem()
        selectDeviceMenu.title = "Select target device"
        statusBarMenu.addItem(selectDeviceMenu)
        
        // Create the noise cancellation submenu
        let ncSubmenu = NSMenu()
        ncSubmenu.autoenablesItems = false
        let ncOffItem = NSMenuItem(title: "Off",
                                   action: #selector(noiseCancellationOff),
                                   keyEquivalent: "")
        let ncMediumItem = NSMenuItem(title: "Medium",
                                      action: #selector(noiseCancellationMedium),
                                      keyEquivalent: "")
        let ncHighItem = NSMenuItem(title: "High",
                                    action: #selector(noiseCancellationHigh),
                                    keyEquivalent: "")
        
        ncSubmenu.addItem(ncOffItem)
        ncSubmenu.addItem(ncMediumItem)
        ncSubmenu.addItem(ncHighItem)
        
        // Create the select device submenu
        let selectDeviceSubmenu = NSMenu()
        selectDeviceSubmenu.delegate = self
        self.selectDeviceMenu = selectDeviceSubmenu
        selectDeviceSubmenu.autoenablesItems = false
        let refreshButton = NSMenuItem(title: "Refresh...",
                                       action: #selector(refreshPairedDevicesList),
                                       keyEquivalent: "")
        refreshButton.isAlternate = true
        
        selectDeviceSubmenu.addItem(refreshButton)
    
        // Set the appropriate submenus
        noiseCancellationMenu.submenu = ncSubmenu
        selectDeviceMenu.submenu = selectDeviceSubmenu
        
        // Add the Quit item
        statusBarMenu.addItem(withTitle: "Quit",
                              action: #selector(quit),
                              keyEquivalent: "")
    }
}

// MARK: - Bluetooth specific methods
extension AppDelegate {
    private func setupConnectionToHeadphones() {
        // Get all the paired devices
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            print("No paired devices found")
            return
        }
        
        if devices.isEmpty {
            print("No paired devices found")
            return
        }
        
        // Add a separator item
        let separatorItem = NSMenuItem.separator()
        self.selectDeviceMenu.addItem(separatorItem)
        
        // Append the found devices to the list
        self.pairedDevices.append(contentsOf: devices)
        
        // Set up the initial menus
        devices.forEach { device in
            let deviceItem = NSMenuItem(title: device.nameOrAddress ?? "unknown",
                                        action: #selector(deviceSelected(sender:)),
                                        keyEquivalent: "")
            deviceItem.indentationLevel = 1
            deviceItem.title = device.nameOrAddress ?? "unknown"
            self.selectDeviceMenu.addItem(deviceItem)
        }
    }
    
    func connectToDevice(with name: String) -> Bool {
        guard let device = self.pairedDevices.first(where: { $0.name == name }) else {
            print("Could not find the selected device")
            return false
        }
        
        var ret: IOReturn!
        ret = device.performSDPQuery(self, uuids: [])
        
        if ret != kIOReturnSuccess {
            fatalError("SDP Query unsuccessful")
        }
        
        // Check if the device contains the required service.
        // Only if SPP Dev is available, these are probably the right headphones
        guard let services = device.services as? [IOBluetoothSDPServiceRecord],
            let serviceHeadset = services.first(where: { service -> Bool in
                service.getServiceName() == "SPP Dev"
            }) else {
                print("Could not find the required service.")
                return false
        }
        
        // Prepare to open an rfcomm channel to the headphones
        // Channel Id always comes in a sequence 8 8 9 9 8 8 9 9 ... -> in this context it is irrelevant
        var channelId: BluetoothRFCOMMChannelID = BluetoothRFCOMMChannelID()
        serviceHeadset.getRFCOMMChannelID(&channelId) // Add a check for the returned value later
        
        // Open a rfcomm channel to the headset
        // Headphones use the "SPP Dev" service to provide information for the app on iOS devices, we can use the same one here
        var channel: IOBluetoothRFCOMMChannel? = nil
        
        let ret2 = device.openRFCOMMChannelSync(&channel,
                                                withChannelID: channelId,
                                                delegate: self)
        
        // Set the reference for later
        self.channel = channel
        if ret2 != kIOReturnSuccess {
            fatalError("Failed to open an rfcomm channel")
        }
        
        IOBluetoothRFCOMMChannel.register(forChannelOpenNotifications: self,
                                          selector: #selector(newRFCOMMChannelOpened),
                                          withChannelID: channelId,
                                          direction: kIOBluetoothUserNotificationChannelDirectionIncoming)
        
        // If everything went okay, return true
        return true
    }
    
    @objc func newRFCOMMChannelOpened(userNotification: IOBluetoothUserNotification,
                                      channel: IOBluetoothRFCOMMChannel) {
        print("New channel opened: \(channel.getID()), isOpen: \(channel.isOpen()), isIncoming: \(channel.isIncoming())")
        channel.setDelegate(self)
    }
}

// MARK: - RFCOMMChannel delegate methods
extension AppDelegate: IOBluetoothRFCOMMChannelDelegate {
    
}

// MARK: - Menu item selection handlers
extension AppDelegate {
    @objc func quit() {
        print("Quitting the menu...")
        self.statusBarMenu.cancelTracking()
        exit(-1)
    }
    
    @objc func noiseCancellationOff() {
        print("Turning the noise cancellation off")
        var data: [UInt8] = [0x01, 0x06, 0x02, 0x01, 0x00]
        // If the channel is open send the appropriate data on it. How did I figure out what to send? Check README.md for information
        if let isOpen = self.channel?.isOpen(), isOpen {
            var result: [UInt8] = []
            let ret = channel?.writeAsync(&data, length: UInt16(data.count), refcon: &result)
            print(krToString(ret!))
        } else {
            print("The channel is not open")
        }
    }
    
    @objc func noiseCancellationMedium() {
        print("Turning the noise cancellation to medium setting")
        var data: [UInt8] = [0x01, 0x06, 0x02, 0x01, 0x03]
        if let isOpen = self.channel?.isOpen(), isOpen {
            var result: [UInt8] = []
            let ret = channel?.writeAsync(&data, length: UInt16(data.count), refcon: &result)
            print(krToString(ret!))
        } else {
            print("The channel is not open")
        }
    }
    
    @objc func noiseCancellationHigh() {
        print("Turning the noise cancellation to high setting")
        var data: [UInt8] = [0x01, 0x06, 0x02, 0x01, 0x01]
        if let isOpen = self.channel?.isOpen(), isOpen {
            var result: [UInt8] = []
            let ret = channel?.writeAsync(&data, length: UInt16(data.count), refcon: &result)
            print(krToString(ret!))
        } else {
            print("The channel is not open")
        }
    }
    
    @objc func refreshPairedDevicesList() {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            print("No paired devices found")
            return
        }
        
        devices.forEach { device in
            let deviceItem = NSMenuItem(title: device.name, action: #selector(deviceSelected(sender:)), keyEquivalent: "")
            deviceItem.title = device.name
            self.selectDeviceMenu.addItem(deviceItem)
        }
    }
    
    @objc func deviceSelected(sender: Any) {
        guard let senderItem = sender as? NSMenuItem else {
            print("Invalid sender. Something went wrong")
            return
        }
        
        // Connect to the device with a name that is equal to the sender title
        if self.connectToDevice(with: senderItem.title) {
            print("Successfully connected to the Bose headphones")
        } else {
            print("Something went wrong")
        }
    }
    
    func krToString (_ kr: kern_return_t) -> String {
        if let cStr = mach_error_string(kr) {
            return String (cString: cStr)
        } else {
            return "Unknown kernel error \(kr)"
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // TODO: called when user clicks the icon on the status bar
        
    }
    
    func menuDidClose(_ menu: NSMenu) {
        
    }
}
