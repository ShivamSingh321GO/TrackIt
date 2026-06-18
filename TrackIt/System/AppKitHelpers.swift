import SwiftUI
import AppKit

// MARK: - Window Accessor Helper
struct WindowAccessor: NSViewRepresentable {
    var onChange: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onChange(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            onChange(window)
        }
    }
}

// MARK: - Drag Background helper to swallow double clicks
struct DragBackground: NSViewRepresentable {
    var color: NSColor
    
    func makeNSView(context: Context) -> NSView {
        return DragNSView(color: color)
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let dragView = nsView as? DragNSView {
            dragView.bgColor = color
            dragView.needsDisplay = true
        }
    }
}

class DragNSView: NSView {
    var bgColor: NSColor
    
    init(color: NSColor) {
        self.bgColor = color
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        bgColor.setFill()
        dirtyRect.fill()
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            // Swallow double clicks to prevent system zoom action
            return
        }
        self.window?.performDrag(with: event)
    }
}

// MARK: - Visual Effect View for macOS
class DraggableVisualEffectNSView: NSVisualEffectView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            return
        }
        self.window?.performDrag(with: event)
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = DraggableVisualEffectNSView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
