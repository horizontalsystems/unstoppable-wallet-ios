import SwiftUI

struct PlaceholderViewNew<Content: View>: View {
    let image: Image
    let text: String
    let additionalContent: Content

    init(image: Image, text: String, @ViewBuilder additionalContent: () -> Content) {
        self.image = image
        self.text = text
        self.additionalContent = additionalContent()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: .margin32) {
                    ZStack {
                        Circle()
                            .fill(Color.themeRaina)
                            .frame(width: 100, height: 100)

                        image
                            .renderingMode(.template)
                            .foregroundColor(.themeGray)
                    }

                    Text(text)
                        .font(.themeSubhead2)
                        .foregroundColor(.themeGray)
                        .multilineTextAlignment(.center)

                    additionalContent
                }
                .frame(width: 264)
                .padding(.bottom, proxy.size.height / 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension PlaceholderViewNew where Content == EmptyView {
    init(image: Image, text: String) {
        self.init(image: image, text: text, additionalContent: { EmptyView() })
    }
}
