import SwiftUI

struct ThemeView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.themeTyler.ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 0)
                    .background(Color.themeTyler)
                    .zIndex(100)

                content
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeNavigationStack<Content: View>: View {
    private let content: Content
    private let path: Binding<NavigationPath>?

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        path = nil
    }

    init(path: Binding<NavigationPath>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.path = path
    }

    var body: some View {
        Group {
            if let path {
                NavigationStack(path: path) {
                    content
                }
            } else {
                NavigationStack {
                    content
                }
            }
        }
        .tint(.themeLeah)
    }
}
