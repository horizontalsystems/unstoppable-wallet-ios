import SwiftUI

struct ThemeView<Content: View>: View {
    var style: Style = .regular
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.themeTyler.ignoresSafeArea()

            decoration

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

    @ViewBuilder private var decoration: some View {
        switch style {
        case .regular:
            EmptyView()
        case .topGradient:
            GeometryReader { proxy in
                LinearGradient(
                    colors: [Color.themeLime, Color.themeLime.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.size.height * 0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .allowsHitTesting(false)
        case .bottomGradient:
            GeometryReader { proxy in
                Circle()
                    .fill(Color.themeLime.opacity(0.2))
                    .frame(width: 650, height: 650)
                    .blur(radius: 100)
                    .position(x: proxy.size.width / 2, y: proxy.size.height + 125)
            }
            .ignoresSafeArea()
            .clipped()
            .allowsHitTesting(false)
        }
    }
}

extension ThemeView {
    enum Style {
        case regular
        case topGradient
        case bottomGradient
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
