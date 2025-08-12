import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var namespace = "scroll_offset"
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()

        if next > 0 {
            value = next
        }
    }
}

struct ScrollHeaderModifier: ViewModifier {
    @State private var scrollOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: ScrollOffsetPreferenceKey.namespace)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .background {
                VStack {
                    Color.themeTyler.frame(height: max(0, scrollOffset)).frame(maxWidth: .infinity)
                    Spacer()
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func themeListTopView() -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named(ScrollOffsetPreferenceKey.namespace)).minY
                    )
            }
        )
    }

    func themeListScrollHeader() -> some View {
        modifier(ScrollHeaderModifier())
    }
}
