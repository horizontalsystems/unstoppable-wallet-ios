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
                Text("premium.cell.title".localized).textHeadline1(color: .themeYellow)
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: .margin4) {
                    ThemeText("premium.cell.description".localized("premium.cell.description.key".localized), style: .subhead, colorStyle: .primary)

                    if let introductoryOffer {
                        Text(introductoryOffer).textCaptionSB(color: .themeGreen)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: 138))
        }
        .background(Color.themeDarker)
    }
}
