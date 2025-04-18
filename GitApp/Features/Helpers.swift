//
//  Helpers.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import AppKit
import SwiftUI

fileprivate var windowsDictionary = [String: NSWindow]()

public func manageOverlayWindow<Content: View>(
    with view: Content,
    id: String,
    at position: CGPoint? = nil,
    withWidth width: CGFloat = 300,
    andHeight height: CGFloat = 300,
    showDuration: TimeInterval? = 3.0
) {
    // Calculate screen frame
    guard let screenFrame = NSScreen.main?.visibleFrame else {
        print("Error: Unable to determine screen frame.")
        return
    }
    
    // Determine window position
    var windowRect = NSRect(origin: .zero, size: CGSize(width: width, height: height))
    
    if let position = position {
        windowRect.origin = position
    } else {
        // Center horizontally
        windowRect.origin.x = (screenFrame.width - width) / 2
        // Align to top with a margin
        windowRect.origin.y = screenFrame.maxY  - 80 // Adjust 20 as needed for margin
    }
    
    // Create or update window
    if let existingWindow = windowsDictionary[id] {
        // Update existing window content
        if let hostingView = existingWindow.contentView as? NSHostingView<Content> {
            hostingView.rootView = view
        } else {
            existingWindow.contentView = NSHostingView(rootView: view)
        }
        
        // Show the window with animation
        withAnimation {
            existingWindow.makeKeyAndOrderFront(nil)
        }
        
    } else {
        // Create a new window
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: view)
        windowsDictionary[id] = window
        
        // Show the window with animation
        withAnimation {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    // Automatically hide the window after the specified duration, if provided
    if let showDuration = showDuration {
        DispatchQueue.main.asyncAfter(deadline: .now() + showDuration) {
            if let window = windowsDictionary[id] {
                withAnimation {
                    window.orderOut(nil)
                }
            }
        }
    }
}

public func openNewWindow<Content: View>(with view: Content,id: String, title: String = "New Window", width: CGFloat = 300, height: CGFloat = 200) {
    let newWindowView = NSHostingController(rootView: view)
    
    // Create the window and set properties
    let newWindow = NSWindow(contentViewController: newWindowView)
    newWindow.title = title
    newWindow.setContentSize(NSSize(width: width, height: height))
    newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
    newWindow.center()
    newWindow.standardWindowButton(.toolbarButton)
    windowsDictionary[id] = newWindow
    newWindow.makeKeyAndOrderFront(nil)
}

public func getWindowBy(id: String) -> NSWindow?  {
    guard let window = windowsDictionary[id] else  { return nil }
    return window
}

public func closeWindow(from windowId: String) {
    guard let window = getWindowBy(id: windowId) else { return }
    window.close()
}


public func getWindowPostionBy(id:String) -> CGPoint? {
    guard let window = windowsDictionary[id] else { return nil }
    return window.frame.origin
}
