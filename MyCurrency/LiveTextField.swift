import SwiftUI
import AppKit

/// NSTextField subclass — textDidChange is a direct override, not a delegate/notification.
/// Guaranteed to fire on every keystroke regardless of window type.
private class CallbackTextField: NSTextField {
    var onChange: ((String) -> Void)?

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        onChange?(stringValue)
    }
}

struct LiveTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let onEdit: (String) -> Void

    func makeNSView(context: Context) -> CallbackTextField {
        let field = CallbackTextField()
        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .right
        field.font = .rounded(ofSize: 24, weight: .semibold)
        field.onChange = { [weak field] value in
            guard let field else { return }
            context.coordinator.didChange(field: field, value: value)
        }
        return field
    }

    func updateNSView(_ field: CallbackTextField, context: Context) {
        context.coordinator.parent = self          // keep closure/binding current
        if field.stringValue != text {
            field.stringValue = text               // programmatic — does NOT call textDidChange
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: Coordinator
    class Coordinator: NSObject {
        var parent: LiveTextField

        init(_ p: LiveTextField) { parent = p }

        func didChange(field: CallbackTextField, value: String) {
            parent.text = value        // update the @Binding
            parent.onEdit(value)       // run conversion
        }
    }
}

private extension NSFont {
    static func rounded(ofSize size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        guard let desc = base.fontDescriptor.withDesign(.rounded) else { return base }
        return NSFont(descriptor: desc, size: size) ?? base
    }
}
