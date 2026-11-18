import SwiftUI

struct SubscribePeriodView: View {
    let item: PurchaseProductItemFactory.Item
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Cell(
            left: {
                CheckBoxView(checked: isSelected)
            },
            middle: {
                MultiText(
                    title: item.title,
                    badge: item.discountBadge.map { ComponentBadge(text: $0, mode: .solidWith(colorStyle: .green), colorStyle: .lawrence) },
                    subtitle: ComponentText(text: item.price.description, colorStyle: .secondary),
                    subtitle2: item.priceDescription.map { ComponentText(text: $0.description, colorStyle: item.priceDescripionAccented ? .green : .secondary) }
                )
            },
            action: action
        )
        .accessibilityIdentifier(TestTags.premiumPlan(item.product.id))
    }
}
