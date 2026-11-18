import SwiftUI

public struct ThemeView<Content: View>: View {
    private let style: ViewStyle
    private let content: Content

    public init(style: ViewStyle = .regular, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    public var body: some View {
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

public enum ViewStyle {
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

public struct ThemeNavigationStack<Content: View>: View {
    private let content: Content
    private let path: Binding<NavigationPath>?

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
        path = nil
    }

    public init(path: Binding<NavigationPath>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.path = path
    }

    public var body: some View {
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

struct EmptyThemeNavigationStack<Content: View>: View {
    @State private var path = NavigationPath()
    let content: (Binding<NavigationPath>) -> Content

    init(@ViewBuilder content: @escaping (Binding<NavigationPath>) -> Content) {
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $path) {
            content($path)
        }
        .tint(.themeLeah)
    }
}

struct ConfirmationButtonStyle: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    var isActive: Bool = true

    func body(content: Content) -> some View {
        if isActive, isEnabled {
            if #available(iOS 26, *) {
                content
                    .buttonStyle(.glassProminent)
                    .tint(.themeBrand)
                    .foregroundStyle(Color.themeWhite)
            } else {
                content
                    .foregroundStyle(Color.themeBrand)
            }
        } else {
            content
        }
    }
}
