import SwiftUI

struct ThemeView<Content: View>: View {
    var style: ViewStyle = .regular
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            style.background.ignoresSafeArea()

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

enum ViewStyle {
    case regular
    case list

    var background: Color {
        switch self {
        case .regular: return .themeTyler
        case .list: return .themeLawrence
        }
    }
}

struct ScrollableThemeView<Content: View>: View {
    var style: ViewStyle = .regular
    @ViewBuilder let content: Content

    var body: some View {
        ThemeView(style: style) {
            ScrollView {
                content
            }
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
        .tint(.themeGray)
    }
}
