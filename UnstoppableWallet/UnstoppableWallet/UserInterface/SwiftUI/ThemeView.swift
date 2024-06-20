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

struct ThemeRadialView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.themeTyler.ignoresSafeArea()

                ZStack {
                    let size = proxy.size.height / 3.5

                    Circle()
                        .fill(Color(hex: 0x003C74))
                        .frame(width: size, height: size)
                        .blur(radius: size / 2)
                        .offset(x: proxy.size.width / 2, y: size / 2)

                    Circle()
                        .fill(Color(hex: 0xFF9B26, alpha: 0.5))
                        .frame(width: size, height: size)
                        .blur(radius: size / 2)
                        .offset(x: 0, y: 0)

                    Circle()
                        .fill(Color(hex: 0xEDD716, alpha: 0.7))
                        .frame(width: size, height: size)
                        .blur(radius: size / 3)
                        .offset(x: -proxy.size.width / 2, y: -size / 2)
                }

                content
            }
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
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.themeJacob)
    }
}
