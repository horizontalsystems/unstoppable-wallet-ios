import SwiftUI

struct ThemeView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.themeTyler.edgesIgnoringSafeArea(.all)
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
