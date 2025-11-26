import SwiftUI

struct BlackFridayPremiumSlideView: View {
    @StateObject var viewModel = BlackFridayPremiumSlideViewModel()

    var body: some View {
        ZStack(alignment: .trailing) {
            Image(viewModel.themeMode.colorScheme == .dark ? "bf_banner_premium" : "bf_banner_premium_light")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()

            VStack(alignment: .leading, spacing: .margin6) {
                HStack(alignment: .center, spacing: .margin16) {
                    VStack(spacing: 5) {
                        Image("bf_black")
                            .resizable()
                            .frame(width: 174, height: 24)

                        Image("bf_friday")
                            .resizable()
                            .frame(width: 174, height: 24)
                    }

                    Spacer()

                    HStack(spacing: -16) {
                        Image("bf_50")
                            .resizable()
                            .frame(width: 100, height: 53)
                        Image("bf_percent")
                            .resizable()
                            .frame(width: 54, height: 53)
                    }
                }

                ThemeText(BlackFridayPremiumHeaderView.description(font: TextStyle.subhead.font), style: .subhead)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin16))
        }
        .background(Color.themeDarker)
    }
}
