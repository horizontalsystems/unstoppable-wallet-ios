import SwiftUI

struct BlackFridayPremiumSlideView: View {
    @StateObject var viewModel = BlackFridayPremiumSlideViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Image(viewModel.themeMode.colorScheme ?? colorScheme == .dark ? "bf_banner_premium" : "bf_banner_premium_light")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center) {
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

                    ThemeText(
                        BlackFridayPremiumHeaderView.description(font: TextStyle.subhead.font),
                        style: .subhead
                    )
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.margin16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
