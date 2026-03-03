import SwiftUI

struct ComponentInformedTitle: CustomStringConvertible {
    let title: String
    let info: InfoDescription

    var description: String { title }

    init(_ title: String, info: InfoDescription) {
        self.title = title
        self.info = info
    }
}

struct ComponentCopyableValue: CustomStringConvertible {
    let text: String
    let value: String?

    var description: String { text }

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

    @ViewBuilder func copyable(_ source: CustomStringConvertible) -> some View {
        if let copyable = source as? ComponentCopyableValue {
            Button {
                CopyHelper.copyAndNotify(value: copyable.value ?? copyable.text)
            } label: {
                self
            }
            .buttonStyle(SecondaryButtonStyle())
        } else {
            self
        }
    }

    @ViewBuilder func styled(_ title: CustomStringConvertible) -> some View {
        informed(title).copyable(title)
    }
}
