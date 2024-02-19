import SwiftUI

struct LazyView<Content: View>: View {
    var content: () -> Content

    var body: some View {
        content()
    }
}
