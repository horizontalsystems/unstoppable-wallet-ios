import SwiftUI

enum PlaceholderLayoutType {
    case upperMiddle
    case middle

    var multiplier: CGFloat {
        switch self {
        case .upperMiddle: return -0.15
        case .middle: return 0
        }
    }
}

struct PlaceholderWrapperViewNew<Content: View>: View {
    var layoutType: PlaceholderLayoutType = .upperMiddle
    @ViewBuilder var content: Content

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                content
                    .background(
                        GeometryReader { contentProxy in
                            Color.clear
                                .onAppear {
                                    contentHeight = contentProxy.size.height
                                }
                                .onChange(of: contentProxy.size.height) { newHeight in
                                    contentHeight = newHeight
                                }
                        }
                    )
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height / 2 + (proxy.size.height - contentHeight) / 2 * layoutType.multiplier
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct PlaceholderViewNew<Content: View>: View {
    let icon: String
    var title: String?
    var subtitle: String?
    var layoutType: PlaceholderLayoutType = .upperMiddle
    @ViewBuilder var additionalContent: Content

    var body: some View {
        PlaceholderWrapperViewNew(layoutType: layoutType) {
            ErrorMessage(icon: icon, title: title, subtitle: subtitle) {
                additionalContent
            }
        }
    }
}

extension PlaceholderViewNew where Content == EmptyView {
    init(icon: String, title: String? = nil, subtitle: String? = nil) {
        self.init(icon: icon, title: title, subtitle: subtitle, additionalContent: { EmptyView() })
    }
}
