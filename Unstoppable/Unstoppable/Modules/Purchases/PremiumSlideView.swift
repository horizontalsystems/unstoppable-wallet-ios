import SwiftUI

struct PremiumSlideView: View {
    let introductoryOffer: String?

    var body: some View {
        ZStack(alignment: .trailing) {
            GeometryReader { geometry in
                Image("banner_premium")
                    .clipped()
                    .frame(width: geometry.size.width, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: .margin2) {
                ThemeText("premium.cell.title".localized, style: .headline1, colorStyle: .yellow)
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: .margin4) {
                    ThemeText("premium.cell.description".localized("premium.cell.description.key".localized), style: .subhead, colorStyle: .bright)

                    if let introductoryOffer {
                        ThemeText(introductoryOffer, style: .captionSB, colorStyle: .green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: 138))
        }
        .background(Color.themeDarker)
    }
}
