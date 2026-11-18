import SwiftUI

struct SubscribePeriodSegmentView: View {
    let items: [PurchaseProductItemFactory.Item]
    @Binding var selection: PurchaseProductItemFactory.Item?
    let onPromoCode: () -> Void

    var body: some View {
        ListSection {
            ForEach(items, id: \.self) { item in
                PremiumFactory.subscribePeriodView(item: item, isSelected: selection == item) {
                    selection = item
                }
            }

            Cell(
                middle: {
                    ThemeText("purchases.period.button.promo".localized, style: .headline2)
                },
                right: {
                    Image.disclosureIcon
                },
                action: onPromoCode
            )
            .accessibilityIdentifier(TestTags.premiumPlansPromoCode)
        }
        .themeListStyle(.bordered)
    }
}
