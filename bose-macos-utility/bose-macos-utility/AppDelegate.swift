//
//  AppDelegate.swift
//  bose-macos-utility
//
//  Created by Łukasz Zalewski on 23/06/2021.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep a reference to the status bar item to keep it alive throughout the whole lifetime of the application
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initalize the menu bar extra
        let statusBar = NSStatusBar.system
        
        let statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        self.statusBarItem = statusBarItem
        // TODO: use the template image, so that the icon is changed when the dark/light mode settings change
        statusBarItem.button?.title = "🎧"
        let statusBarMenu = NSMenu(title: "first menu")
        self.statusBarMenu = statusBarMenu
        statusBarItem.menu = statusBarMenu
        
        statusBarMenu.addItem(withTitle: "Quit",
                              action: #selector(quit),
                              keyEquivalent: "")
    }
    
    @objc func quit() {
        print("Quitting the menu...")
        self.statusBarMenu.cancelTracking()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

