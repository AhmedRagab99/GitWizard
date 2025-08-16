import AppKit
import SwiftUI

// MARK: - Weak reference wrapper
fileprivate class WeakWindowRef {
    weak var window: NSWindow?
    init(_ window: NSWindow) { self.window = window }
}

// MARK: - Window state tracking
fileprivate var windowsDictionary = [String: WeakWindowRef]()
fileprivate let windowManagerDelegate = WindowManagerDelegate()

// MARK: - Delegate for cleanup
fileprivate class WindowManagerDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else { return }

        // Find key and remove
        if let key = windowsDictionary.first(where: { $0.value.window === closedWindow })?.key {
            print("Window with ID '\(key)' is closing. Removing from manager.")
            windowsDictionary.removeValue(forKey: key)
        }
    }
}

// MARK: - Overlay windows (auto close)
public func manageOverlayWindow<Content: View>(
    with view: Content,
    id: String,
    at position: CGPoint? = nil,
    withWidth width: CGFloat = 300,
    andHeight height: CGFloat = 300,
    showDuration: TimeInterval? = 3.0
) {
    guard let screenFrame = NSScreen.main?.visibleFrame else {
        print("Error: Unable to determine screen frame.")
        return
    }

    var windowRect = NSRect(origin: .zero, size: CGSize(width: width, height: height))
    if let position = position {
        windowRect.origin = position
    } else {
        windowRect.origin.x = (screenFrame.width - width) / 2
        windowRect.origin.y = screenFrame.maxY - 80
    }

    // Either reuse or create
    if let existing = getWindowBy(id: id) {
        if let hostingView = existing.contentView as? NSHostingView<Content> {
            hostingView.rootView = view
        } else {
            existing.contentView = NSHostingView(rootView: view)
        }
        existing.makeKeyAndOrderFront(nil)
        existing.alphaValue = 1.0
    } else {
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
        window.delegate = windowManagerDelegate

        windowsDictionary[id] = WeakWindowRef(window)

        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            window.animator().alphaValue = 1.0
        }
    }

    // Auto close after duration
    if let duration = showDuration {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if let windowToClose = getWindowBy(id: id) {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.3
                    windowToClose.animator().alphaValue = 0
                }, completionHandler: {
                    windowToClose.close() // frees memory
                })
            }
        }
    }
}

// MARK: - New titled windows
public func openNewWindow<Content: View>(
    with view: Content,
    id: String,
    title: String = "New Window",
    width: CGFloat = 300,
    height: CGFloat = 200
) {
    if let existing = getWindowBy(id: id) {
        existing.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    let controller = NSHostingController(rootView: view)
    let window = NSWindow(contentViewController: controller)
    window.title = title
    window.setContentSize(NSSize(width: width, height: height))
    window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
    window.center()
    window.delegate = windowManagerDelegate

    windowsDictionary[id] = WeakWindowRef(window)

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

// MARK: - Utility functions
public func getWindowBy(id: String) -> NSWindow? {
    return windowsDictionary[id]?.window
}

public func closeWindow(from windowId: String) {
    guard let window = getWindowBy(id: windowId) else {
        print("Window with ID '\(windowId)' not found.")
        return
    }
    window.close() // triggers delegate cleanup
}

public func getWindowPostionBy(id: String) -> CGPoint? {
    return getWindowBy(id: id)?.frame.origin
}

public func bringWindowToFront(id: String) {
    guard let window = getWindowBy(id: id), window.isVisible else { return }
    window.makeKeyAndOrderFront(nil)
}

public func isWindowVisible(id: String) -> Bool {
    return getWindowBy(id: id)?.isVisible ?? false
}

public func doesWindowExist(id: String) -> Bool {
    return getWindowBy(id: id) != nil
}
