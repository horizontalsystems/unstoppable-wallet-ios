import Foundation
import SwiftUI

struct PremiumHeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("box_2")
                .padding(.vertical, .margin24)

            Text(title)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 52)
                .padding(.bottom, .margin24)
        }
    }

    private var title: AttributedString {
        let text = "premium.cell.description".localized("premium.cell.description.key".localized)
        var attributedString = AttributedString(text)
        attributedString.font = .headline1
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
