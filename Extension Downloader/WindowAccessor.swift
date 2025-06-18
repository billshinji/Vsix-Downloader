import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.styleMask.insert(.resizable)
                window.setContentSize(window.contentView?.intrinsicContentSize ?? NSSize(width: 400, height: 400))
                window.center()
                window.isReleasedWhenClosed = false
            }
        }
        return nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
