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
    private let circleDiameter: CGFloat = 250
    var radialPositions: ThemeRadialPosition = .center

    var left: UInt? = 0xEDD716
    var center: UInt? = 0xFF9B26
    var right: UInt? = 0x003C74

    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.themeTyler.ignoresSafeArea()

                ZStack {
                    let windowSize = UIScreen.currentSize

                    let viewSize = proxy.size
                    let deltaHeight = (windowSize.height - viewSize.height) / 2
                    let offsets = offsets(viewSize: viewSize, deltaHeight: deltaHeight)

                    if let left {
                        Circle()
                            .fill(Color(hex: left, alpha: 0.6))
                            .frame(width: circleDiameter, height: circleDiameter)
                            .blur(radius: 100)
                            .offset(x: offsets.left.x, y: offsets.left.y)
                    }

                    if let center {
                        Circle()
                            .fill(Color(hex: center, alpha: 0.7))
                            .frame(width: circleDiameter, height: circleDiameter)
                            .blur(radius: 150)
                            .offset(x: offsets.center.x, y: offsets.center.y)
                    }

                    if let right {
                        Circle()
                            .fill(Color(hex: right))
                            .frame(width: circleDiameter, height: circleDiameter)
                            .blur(radius: 150)
                            .offset(x: offsets.right.x, y: offsets.right.y)
                    }
                }

                content
            }
        }
    }

    private func offsets(viewSize: CGSize, deltaHeight: CGFloat) -> (left: CGPoint, center: CGPoint, right: CGPoint) {
        switch radialPositions {
        case .center:
            (
                left: .init(x: -1 * viewSize.width / 2, y: deltaHeight - circleDiameter / 2),
                center: .init(x: 0, y: deltaHeight),
                right: .init(x: viewSize.width / 2, y: deltaHeight + circleDiameter / 2)
            )
        case .corners:
            (
                left: CGPoint(x: -viewSize.width / 2, y: -viewSize.height / 2),
                center: CGPoint(x: 0, y: deltaHeight),
                right: CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
            )
        }
    }
}

enum ThemeRadialPosition {
    case center
    case corners
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

extension ThemeNavigationStack {
    init<PathContent: View>(
        @ViewBuilder content: @escaping (Binding<NavigationPath>) -> PathContent
    ) where Content == _AutoPathWrapper<PathContent> {
        self.init {
            _AutoPathWrapper(content: content)
        }
    }
}

struct _AutoPathWrapper<Content: View>: View {
    @State private var path = NavigationPath()
    let content: (Binding<NavigationPath>) -> Content

    var body: some View {
        content($path)
    }
}
