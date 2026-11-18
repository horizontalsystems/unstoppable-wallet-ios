import SwiftUI

enum PremiumFactory {
    /// Purchase main+success views header
    static func header(title: AttributedString) -> some View {
        PremiumHeaderView(title: title)
    }

    /// Purchase main+success views background
    static func background(@ViewBuilder _ content: () -> some View) -> some View {
        ZStack {
            WelcomeGlowView(start: nil)
            content()
        }
    }

    /// Purchase select type bottom sheet
    static var productItemFactory: PurchaseProductItemFactory {
        PurchaseProductItemFactory()
    }

    static func subscribePeriodView(item: PurchaseProductItemFactory.Item, isSelected: Bool, action: @escaping () -> Void) -> some View {
        SubscribePeriodView(
            item: item,
            isSelected: isSelected,
            action: action
        )
    }
}
