import SwiftUI

struct PremiumListSectionHeader: View {
    var body: some View {
        HStack(spacing: .margin6) {
            Image("star_filled_16")
                .renderingMode(.template)
                .foregroundColor(.themeJacob)

            Text("subscription.premium.label".localized)
                .themeSubhead1(color: .themeJacob)
        }
        .padding(EdgeInsets(top: .margin6, leading: .margin16, bottom: 0, trailing: .margin16))
        .frame(height: .margin32, alignment: .top)
    }
}
