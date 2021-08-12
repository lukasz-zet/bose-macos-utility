//
//  NSMenuExtended.swift
//  bose-macos-utility
//
//  Created by Łukasz Zalewski on 12/08/2021.
//

import Foundation
import Cocoa


class NSMenuExtended: NSMenuItem {
    override init(title string: String, action selector: Selector?, keyEquivalent charCode: String) {
        super.init(title: string,
                   action: selector,
                   keyEquivalent: charCode)
        
        
        let newView = NSViewExtended(frame: self.view!.bounds)
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
