import SwiftUI

struct BlackFridayPremiumHeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Image("bf_black")
                    .padding(.top, 38)
                    .padding(.horizontal, .margin6)

                Image("bf_friday")
                    .padding(.top, 5)
                    .padding(.horizontal, .margin6)

                HStack(spacing: -19) {
                    Image("bf_50")
                    Image("bf_percent")
                }
                .padding(.top, 11)
                .padding(.bottom, 20)
            }
            .padding(.top, .margin24)

            ThemeText(Self.description(font: .headline), style: .headline1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 52)
                .padding(.bottom, .margin24)
        }
    }

    static func description(font: Font) -> AttributedString {
        let text = "premium.cell.black_friday.description".localized("premium.cell.description.key".localized)
        var attributedString = AttributedString(text)
        attributedString.font = font
        attributedString.foregroundColor = .themeLeah

        for range in text.ranges(of: "premium.cell.description.key".localized) {
            if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
               let upperBound = AttributedString.Index(range.upperBound, within: attributedString)
            {
                let attrRange = lowerBound ..< upperBound
                attributedString[attrRange].foregroundColor = .themeJacob
            }
        }

        return attributedString
    }
}
