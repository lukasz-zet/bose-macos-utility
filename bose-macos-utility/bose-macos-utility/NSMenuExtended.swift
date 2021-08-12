//
//  NSMenuExtended.swift
//  bose-macos-utility
//
//  Created by Łukasz Zalewski on 12/08/2021.
//

import Foundation
import Cocoa

// TODO: Idea: create a menu item that does not close when clicked upon
class NSMenuExtended: NSMenuItem {
    override init(title string: String, action selector: Selector?, keyEquivalent charCode: String) {
        super.init(title: string,
                   action: selector,
                   keyEquivalent: charCode)
    }
    
    func changeView() {
        let newView = NSViewExtended(frame: self.view!.bounds)
        self.view?.removeFromSuperview()
        self.view = newView
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NSViewExtended: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return false
    }
}
