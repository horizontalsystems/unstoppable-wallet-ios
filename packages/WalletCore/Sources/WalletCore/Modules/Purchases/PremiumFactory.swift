import Foundation
import SwiftUI

enum PremiumFactory {
    /// Purchase main view
    static var header: some View {
        PremiumHeaderView()
    }

    /// MainSettings banner view
    static func slide(offer: String?) -> some View {
        PremiumSlideView(introductoryOffer: offer)
    }

    /// Purchase main+success views Background
    static func radialView(@ViewBuilder _ content: () -> some View) -> some View {
        ThemeRadialView(content: content)
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

    static var forceShowingPremium: Bool {
        false
    }
}
