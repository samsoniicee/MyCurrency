import AppKit
import SwiftUI

struct CurrencyTextField: NSViewRepresentable {
    @Binding var text: String
    var onFocusChange: (Bool) -> Void = { _ in }

    func makeNSView(context: Context) -> SelectTextField {
        let field = SelectTextField()
        field.placeholderString = "0.00"
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .right
        field.font = Self.font(for: "")
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ field: SelectTextField, context: Context) {
        context.coordinator.parent = self
        // Don't overwrite while the user is actively typing
        if field.currentEditor() == nil {
            if field.stringValue != text { field.stringValue = text }
            field.font = Self.font(for: text)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: – Shared formatter (dot decimal, comma thousands)

    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.decimalSeparator = "."
        f.groupingSeparator = ","
        f.groupingSize = 3
        f.usesGroupingSeparator = true
        return f
    }()

    static func format(_ raw: String) -> String? {
        let clean = raw.replacingOccurrences(of: ",", with: "")
        guard let value = Double(clean) else { return nil }
        return formatter.string(from: NSNumber(value: value))
    }

    // Shrink font so large numbers always fit in the field
    static func font(for text: String) -> NSFont {
        let pt: CGFloat
        switch text.count {
        case ..<11: pt = 24
        case 11..<14: pt = 20
        case 14..<17: pt = 17
        default:      pt = 14
        }
        return .rounded(ofSize: pt, weight: .semibold)
    }

    // MARK: – Coordinator

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CurrencyTextField

        init(_ p: CurrencyTextField) { parent = p }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            let text = field.stringValue
            parent.text = text
            // Adapt font live while typing
            field.font = CurrencyTextField.font(for: text)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            // Format the typed value when the user leaves the field
            if let formatted = CurrencyTextField.format(field.stringValue) {
                field.stringValue = formatted
                parent.text = formatted
                field.font = CurrencyTextField.font(for: formatted)
            }
            parent.onFocusChange(false)
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocusChange(true)
        }
    }
}

// MARK: – SelectTextField

final class SelectTextField: NSTextField {
    override func mouseDown(with event: NSEvent) {
        let alreadyEditing = currentEditor() != nil
        super.mouseDown(with: event)
        guard !alreadyEditing else { return }
        DispatchQueue.main.async { [weak self] in
            self?.selectText(nil)
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
