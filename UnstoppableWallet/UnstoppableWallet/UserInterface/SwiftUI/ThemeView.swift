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
    private let circleDiameter: CGFloat = 250

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.themeTyler.ignoresSafeArea()

                ZStack {
                    let windowSize = UIScreen.currentSize
                    let viewSize = proxy.size

                    let deltaHeight = (windowSize.height - viewSize.height) / 2

                    Circle()
                        .fill(Color(hex: 0xEDD716, alpha: 0.6))
                        .frame(width: circleDiameter, height: circleDiameter)
                        .blur(radius: 100)
                        .offset(x: -1 * viewSize.width / 2, y: deltaHeight - circleDiameter / 2)

                    Circle()
                        .fill(Color(hex: 0xFF9B26, alpha: 0.7))
                        .frame(width: circleDiameter, height: circleDiameter)
                        .blur(radius: 150)
                        .offset(x: 0, y: deltaHeight)

                    Circle()
                        .fill(Color(hex: 0x003C74))
                        .frame(width: circleDiameter, height: circleDiameter)
                        .blur(radius: 150)
                        .offset(x: viewSize.width / 2, y: deltaHeight + circleDiameter / 2)
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
