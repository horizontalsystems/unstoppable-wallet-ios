import SwiftUI

struct PlaceholderViewNew<Content: View>: View {
    let icon: String
    var title: String?
    var subtitle: String?
    var layoutType: LayoutType = .upperMiddle
    @ViewBuilder var additionalContent: Content

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ErrorMessage(icon: icon, title: title, subtitle: subtitle) {
                    additionalContent
                }
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

extension PlaceholderViewNew {
    enum LayoutType {
        case upperMiddle
        case middle

        var multiplier: CGFloat {
            switch self {
            case .upperMiddle: return -0.15
            case .middle: return 0
            }
        }
    }
}

extension PlaceholderViewNew where Content == EmptyView {
    init(icon: String, title: String? = nil, subtitle: String? = nil) {
        self.init(icon: icon, title: title, subtitle: subtitle, additionalContent: { EmptyView() })
    }
}
