import SwiftUI

struct PlaceholderViewNew<Content: View>: View {
    let image: Image
    let text: String?
    let layoutType: LayoutType
    let additionalContent: Content

    @State private var contentHeight: CGFloat = 0

    init(image: Image, text: String? = nil, layoutType: LayoutType = .upperMiddle, @ViewBuilder additionalContent: () -> Content) {
        self.image = image
        self.text = text
        self.layoutType = layoutType
        self.additionalContent = additionalContent()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: .margin32) {
                    ZStack {
                        Circle()
                            .fill(Color.themeBlade)
                            .frame(width: 100, height: 100)

                        image
                            .renderingMode(.template)
                            .foregroundColor(.themeGray)
                    }

                    if let text {
                        Text(text)
                            .font(.themeSubhead2)
                            .foregroundColor(.themeGray)
                            .multilineTextAlignment(.center)
                    }

                    additionalContent
                }
                .frame(width: 264)
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
        case bottom

        var multiplier: CGFloat {
            switch self {
            case .upperMiddle: return -0.15
            case .bottom: return 0.5
            }
        }
    }
}

extension PlaceholderViewNew where Content == EmptyView {
    init(image: Image, text: String) {
        self.init(image: image, text: text, additionalContent: { EmptyView() })
    }
}
