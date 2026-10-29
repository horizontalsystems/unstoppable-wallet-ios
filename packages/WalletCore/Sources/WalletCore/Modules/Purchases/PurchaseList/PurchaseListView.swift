import Kingfisher
import MarketKit
import SwiftUI

struct PurchaseListView: View {
    @ObservedObject private var viewModel = PurchaseListViewModel()

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                if let activePurchase = viewModel.activePurchase {
                    status(purchase: activePurchase)

                    if activePurchase.type == .subscription {
                        manageSubscriptionView()
                    }

                    if viewModel.emulatePurchase {
                        debugActionsSubscriptionView()
                    }
                } else {
                    noPurchaseView()
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("subscription.title".localized)
    }

    @ViewBuilder private func row(value: String, action: @escaping () -> Void) -> some View {
        Cell(
            middle: { ThemeText("subscription.plan".localized, style: .headline2) },
            right: {
                ThemeText(value, style: .subheadSB, colorStyle: .yellow)
                    .arrow(style: .disclosure)
            },
            action: action
        )
    }

    @ViewBuilder private func noPurchaseView() -> some View {
        ListSection {
            Cell(
                middle: { ThemeText("subscription.get".localized, style: .headline2) },
                right: { Image.disclosureIcon },
                action: {
                    Coordinator.shared.presentPurchase(page: .purchaseList, trigger: .getPremium)
                }
            )

            Cell(
                middle: { ThemeText("subscription.restore".localized, style: .headline2, colorStyle: .yellow) },
                action: {
                    viewModel.restorePurchases()
                }
            )
        }
    }

    @ViewBuilder private func status(purchase: PurchaseManager.PurchaseData) -> some View {
        ListSection {
            ForEach(viewModel.viewItems(purchase: purchase)) { viewItem in
                Cell(
                    middle: { ThemeText(viewItem.title, style: .subhead) },
                    right: { ThemeText(viewItem.value, style: .subheadSB) }
                )
            }
        }
    }

    @ViewBuilder private func manageSubscriptionView() -> some View {
        ListSection {
            Cell(
                middle: { ThemeText("subscription.manage".localized, style: .headline2) },
                right: { Image.disclosureIcon },
                action: {
                    viewModel.onManageSubscriptions()
                }
            )
        }
    }

    @ViewBuilder private func debugActionsSubscriptionView() -> some View {
        ListSection {
            Cell(
                middle: { ThemeText("Cancel Subscription", style: .headline2) },
                action: {
                    viewModel.debugCancelSubscription()
                }
            )
            Cell(
                middle: { ThemeText("Clear Subscriptions".localized, style: .headline2) },
                action: {
                    viewModel.debugClearSubsctiption()
                }
            )
        }
    }
}
