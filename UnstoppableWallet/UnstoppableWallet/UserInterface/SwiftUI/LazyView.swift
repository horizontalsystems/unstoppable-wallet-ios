import SwiftUI

struct LazyView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: Content {
        content()
    }
}
