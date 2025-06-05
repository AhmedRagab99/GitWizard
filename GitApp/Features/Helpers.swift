//
//  Helpers.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import AppKit
import SwiftUI

// Window state tracking
fileprivate var windowsDictionary = [String: NSWindow]()
fileprivate let windowManagerDelegate = WindowManagerDelegate() // Shared delegate instance

// Custom NSWindowDelegate to handle cleanup
fileprivate class WindowManagerDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else { return }

        // Find and remove the window from the dictionary
        var keyToRemove: String?
        for (key, window) in windowsDictionary {
            if window === closedWindow {
                keyToRemove = key
                break
            }
        }

        if let key = keyToRemove {
            print("Window with ID '\(key)' is closing. Removing from manager.")
            windowsDictionary.removeValue(forKey: key)
        } else {
            // This case might happen if the window was not managed by this system (e.g. main app window if not added)
            // or was already removed programmatically without going through its own close sequence that triggers this delegate.
            print("A window closed but was not found in the windowsDictionary or was already removed: \(closedWindow.title ?? "Untitled")")
        }
    }
}

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
        existingWindow.delegate = windowManagerDelegate // Ensure delegate is set

        // Show the window with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            existingWindow.makeKeyAndOrderFront(nil)
            existingWindow.alphaValue = 1.0
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
        window.delegate = windowManagerDelegate // Set the custom delegate

        // Store window and delegate
        windowsDictionary[id] = window

        // Show the window with animation
        window.alphaValue = 0.0 // Start transparent for fade-in
        window.makeKeyAndOrderFront(nil)
        withAnimation(.easeInOut(duration: 0.2)) {
            window.alphaValue = 1.0
        }
    }

    // Automatically hide the window after the specified duration, if provided
    if let showDuration = showDuration {
        DispatchQueue.main.asyncAfter(deadline: .now() + showDuration) {
            if let windowToClose = windowsDictionary[id] { // Check if it still exists and matches
                 // Animate fade-out
                withAnimation(.easeInOut(duration: 0.3)) {
                    windowToClose.animator().alphaValue = 0
                }
                // After animation, order out and remove
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    windowToClose.orderOut(nil)
                    // For borderless overlay windows, explicitly remove from dictionary
                    // as their closing mechanism might not always trigger windowWillClose
                    // if not conventionally closed.
                    if windowsDictionary[id] === windowToClose { // Ensure it's the same window we intended to close
                        print("Borderless overlay '\(id)' timed out. Removing from manager.")
                        windowsDictionary.removeValue(forKey: id)
                    }
                }
            }
        }
    }
}

public func openNewWindow<Content: View>(
    with view: Content,
    id: String,
    title: String = "New Window",
    width: CGFloat = 300,
    height: CGFloat = 200
) {
    // If a window with this ID exists, bring it to the front.
    if let existingWindow = windowsDictionary[id] {
        print("Window with ID '\(id)' already exists. Making key and ordering front.")
        existingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // Ensure app focus
        return
    }

    // If it was in the dictionary but somehow the window instance is gone (e.g., after a crash recovery attempt or manual niling)
    // remove the old entry. This path should ideally not be hit if delegate works correctly.
    if windowsDictionary[id] != nil && getWindowBy(id: id) == nil {
         windowsDictionary.removeValue(forKey: id)
    }

    let newWindowView = NSHostingController(rootView: view)

    // Create the window and set properties
    let newWindow = NSWindow(contentViewController: newWindowView)
    newWindow.title = title
    newWindow.setContentSize(NSSize(width: width, height: height))
    newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
    newWindow.center()
    // newWindow.standardWindowButton(.toolbarButton) // This is usually automatic

    newWindow.delegate = windowManagerDelegate // Set the custom delegate

    // Store window
    windowsDictionary[id] = newWindow

    newWindow.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true) // Activate app when new window opens
}

public func getWindowBy(id: String) -> NSWindow? {
    guard let window = windowsDictionary[id] else { return nil }
    return window
}

public func closeWindow(from windowId: String) {
    guard let window = getWindowBy(id: windowId) else {
        // If window not in dictionary, but perhaps we have a direct reference elsewhere and want to ensure removal.
        // However, the primary mechanism should be finding it in the dictionary.
        print("Window with ID '\(windowId)' not found in dictionary to close.")
        return
    }
    window.close() // This will trigger windowWillClose via the delegate,
                   // which then removes it from the windowsDictionary.
}

public func getWindowPostionBy(id: String) -> CGPoint? {
    guard let window = windowsDictionary[id] else { return nil }
    return window.frame.origin
}

public func bringWindowToFront(id: String) {
    guard let window = windowsDictionary[id], window.isVisible else { return }
    window.makeKeyAndOrderFront(nil)
}

// Helper to check if a window exists and is visible
public func isWindowVisible(id: String) -> Bool {
    guard let window = windowsDictionary[id] else { return false }
    return window.isVisible
}

// Helper to check if a window exists (visible or not)
public func doesWindowExist(id: String) -> Bool {
    return windowsDictionary[id] != nil
}
