import SwiftUI

struct PremiumHeaderView: View {
    let title: AttributedString

    var body: some View {
        VStack(spacing: .margin16) {
            ZStack {
                ThemeImage("polistar", size: 54, colorStyle: .brand)
            }
            .frame(size: 96)

            ThemeText(title, style: .title3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, .margin64)
        }
    }
}

extension PremiumHeaderView {
    static var premiumTitle: AttributedString {
        let key = "premium.cell.description.key".localized
        let text = "premium.cell.description".localized(key)
        var attributedString = AttributedString(text)
        attributedString.foregroundColor = .themeLeah

        for range in text.ranges(of: key) {
            if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
               let upperBound = AttributedString.Index(range.upperBound, within: attributedString)
            {
                attributedString[lowerBound ..< upperBound].foregroundColor = .themeBrand
            }
        }

        return attributedString
    }

    static func plainTitle(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        attributedString.foregroundColor = .themeLeah
        return attributedString
    }
}
