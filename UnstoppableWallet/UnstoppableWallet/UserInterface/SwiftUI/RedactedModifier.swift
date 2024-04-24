import SwiftUI

struct RedactedModifier: ViewModifier {
    let value: Any?

    func body(content: Content) -> some View {
        content
            .redacted(reason: value == nil ? .placeholder : .init())
            .shimmering(active: value == nil)
    }
}

extension View {
    func redacted(value: Any?) -> some View {
        modifier(RedactedModifier(value: value))
    }
}
