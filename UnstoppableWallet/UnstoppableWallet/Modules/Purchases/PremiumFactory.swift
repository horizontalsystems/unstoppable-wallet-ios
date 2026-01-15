import Foundation
import SwiftUI

enum PremiumFactory {
    // Purchase main view
    @ViewBuilder static var header: some View {
        PremiumHeaderView()
    }

    // MainSettings banner view
    @ViewBuilder static func slide(offer: String?) -> some View {
        PremiumSlideView(introductoryOffer: offer)
    }

    // Purchase main+success views Background
    @ViewBuilder static func radialView(@ViewBuilder _ content: () -> some View) -> some View {
        ThemeRadialView(content: content)
    }

    // Purchase select type bottom sheet
    static var productItemFactory: PurchaseProductItemFactory {
        return PurchaseProductItemFactory()
    }

    @ViewBuilder static func subscribePeriodView(item: PurchaseProductItemFactory.Item, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
