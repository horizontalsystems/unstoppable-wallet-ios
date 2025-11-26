import Foundation
import SwiftUI

enum PremiumFactory {
    private static let blackFridayIntervals: ClosedRange<TimeInterval> = 1_764_028_800 ... 1_765_065_600 // 25.nov.2025 - 7.dec.2025[00:00]

    static var isBlackFriday: Bool {
        blackFridayIntervals.contains(Date().timeIntervalSince1970)
    }

    // Purchase main view
    @ViewBuilder static var header: some View {
        if isBlackFriday {
            BlackFridayPremiumHeaderView()
        } else {
            PremiumHeaderView()
        }
    }

    // MainSettings banner view
    @ViewBuilder static func slide(offer: String?) -> some View {
        if isBlackFriday {
            BlackFridayPremiumSlideView()
        } else {
            PremiumSlideView(introductoryOffer: offer)
        }
    }

    // Purchase main+success views Background
    @ViewBuilder static func radialView(@ViewBuilder _ content: () -> some View) -> some View {
        ThemeRadialView(content: content, blue: !isBlackFriday)
    }

    // Purchase select type bottom sheet
    static var productItemFactory: PurchaseProductItemFactory {
        if isBlackFriday {
            return BlackFridayPurchaseProductItemFactory()
        }

        return PurchaseProductItemFactory()
    }

    @ViewBuilder static func subscribePeriodView(item: PurchaseProductItemFactory.Item, isSelected: Bool, action: @escaping () -> Void) -> some View {
        if let item = item as? BlackFridayPurchaseProductItemFactory.Item {
            BlackFridaySubscribePeriodView(
                item: item,
                isSelected: isSelected,
                action: action
            )
        } else {
            SubscribePeriodView(
                item: item,
                isSelected: isSelected,
                action: action
            )
        }
    }
}
