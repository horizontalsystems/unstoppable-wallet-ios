import SwiftUI

struct PremiumListSectionHeader: View {
    var body: some View {
        HStack(spacing: .margin6) {
            ThemeImage("star_filled", size: .iconSize16, colorStyle: .brand)

            Text("subscription.premium.label".localized)
                .themeSubhead1(color: .themeBrand)
        }
        .padding(EdgeInsets(top: .margin6, leading: .margin16, bottom: 0, trailing: .margin16))
        .frame(height: .margin32, alignment: .top)
    }
}
