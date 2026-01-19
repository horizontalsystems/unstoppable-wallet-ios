import SwiftUI

struct SectionHeader<ImageContent: View>: View {
    private let text: CustomStringConvertible?
    private let imageContent: (() -> ImageContent)?

    init(image: CustomStringConvertible?, text: CustomStringConvertible?) where ImageContent == ThemeImage {
        imageContent = image.map { image in
            { ThemeImage(image, size: .iconSize20) }
        }
        self.text = text
    }

    init(image: @escaping () -> ImageContent, text: CustomStringConvertible?) {
        imageContent = image
        self.text = text
    }

    var body: some View {
        HStack(alignment: .center, spacing: .margin8) {
            imageContent?()

            if let text {
                ThemeText(text, style: .subheadSB)
            }

            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 32, bottom: 12, trailing: 32))
    }
}
