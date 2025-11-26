import SwiftUI

struct SubscribePeriodSegmentView: View {
    @Binding var items: [PurchaseProductItemFactory.Item]
    @Binding var selection: PurchaseProductItemFactory.Item?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                PremiumFactory.subscribePeriodView(item: item, isSelected: selection == item) {
                    selection = item
                }
            }
        }
    }
}
