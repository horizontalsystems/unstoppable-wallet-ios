import SwiftUI

struct SectionHeader<ImageContent: View>: View {
    private let text: CustomStringConvertible?
    private let imageContent: (() -> ImageContent)?
    var horizontalInsets: CGFloat

    init(image: CustomStringConvertible? = nil, text: CustomStringConvertible?, horizontalInsets: CGFloat = .margin32) where ImageContent == ThemeImage {
        imageContent = image.map { image in
            { ThemeImage(image, size: .iconSize20) }
        }
        self.text = text
        self.horizontalInsets = horizontalInsets
    }

    init(image: @escaping () -> ImageContent, text: CustomStringConvertible?, horizontalInsets: CGFloat = .margin32) {
        imageContent = image
        self.text = text
        self.horizontalInsets = horizontalInsets
    }

    var body: some View {
        HStack(alignment: .center, spacing: .margin8) {
            imageContent?()

            if let text {
                ThemeText(text, style: .subheadSB)
            }

            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: horizontalInsets, bottom: 12, trailing: horizontalInsets))
    }
}
