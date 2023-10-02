import SwiftUI

struct ThemeView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.themeTyler.ignoresSafeArea()
            content
        }
    }
}

struct ScrollableThemeView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ThemeView {
            ScrollView {
                content
            }
        }
    }
}

struct ThemeNavigationView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        NavigationView {
            content
        }
        .accentColor(.themeJacob)
    }
}
