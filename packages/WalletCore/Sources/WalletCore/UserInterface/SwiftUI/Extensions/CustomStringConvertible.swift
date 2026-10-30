import SwiftUI

public struct ComponentInformedTitle: CustomStringConvertible {
    let title: String
    let info: InfoDescription

    public var description: String {
        title
    }

    public init(_ title: String, info: InfoDescription) {
        self.title = title
        self.info = info
    }
}

struct ComponentCopyableValue: CustomStringConvertible {
    let text: String
    let value: String?

    var description: String {
        text
    }

    init(_ text: String, value: String? = nil) {
        self.text = text
        self.value = value
    }
}

extension View {
    @ViewBuilder func informed(_ source: CustomStringConvertible) -> some View {
        if let info = (source as? ComponentInformedTitle)?.info {
            modifier(Informed(infoDescription: info, horizontalPadding: 0))
        } else {
            self
        }
    }

    /// Replaces the receiver with a small secondary `ThemeButton` that copies the value when `source` is a `ComponentCopyableValue`; otherwise returns the receiver unchanged.
    @ViewBuilder func copyable(_ source: CustomStringConvertible) -> some View {
        if let copyable = source as? ComponentCopyableValue {
            ThemeButton(text: copyable.text, style: .secondary, size: .small) {
                CopyHelper.copyAndNotify(value: copyable.value ?? copyable.text)
            }
        } else {
            self
        }
    }

    func styled(_ title: CustomStringConvertible) -> some View {
        informed(title).copyable(title)
    }
}
