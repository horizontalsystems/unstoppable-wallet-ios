import Kingfisher
import MarketKit
import SwiftUI

struct PurchaseListView: View {
    @ObservedObject private var viewModel = PurchaseListViewModel()
    @State private var purchasesPresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                if let activePurchase = viewModel.activePurchase {
                    status(purchase: activePurchase)

                    if activePurchase.type == .subscription {
                        manageSubscriptionView()
                    }
                } else {
                    noPurchaseView()
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .sheet(isPresented: $purchasesPresented) {
            PurchasesView()
        }
        .navigationTitle("subscription.title".localized)
    }

    @ViewBuilder private func row(value: String, action: @escaping () -> Void) -> some View {
        ClickableRow(action: action) {
            HStack(spacing: .margin8) {
                HStack {
                    Text("subscription.plan".localized).textBody()
                    Spacer()
                    Text(value).textSubhead1(color: .themeJacob)
                }

                Image.disclosureIcon
            }
        }
    }

    @ViewBuilder private func noPurchaseView() -> some View {
        ListSection {
            ClickableRow {
                purchasesPresented = true
            } content: {
                HStack(spacing: .margin8) {
                    Text("subscription.get".localized).textBody()
                    Spacer()
                    Image.disclosureIcon
                }
            }

            ClickableRow {
                viewModel.restorePurchases()
            } content: {
                Text("subscription.restore".localized).themeBody(color: .themeJacob)
            }
        }
    }

    @ViewBuilder private func status(purchase: PurchaseManager.PurchaseData) -> some View {
        ListSection {
            ForEach(viewModel.viewItems(purchase: purchase)) { viewItem in
                ListRow {
                    HStack(spacing: .margin8) {
                        Text(viewItem.title).textSubhead2()
                        Spacer()
                        Text(viewItem.value).textSubhead1(color: .themeLeah)
                    }
                }
            }
        }
    }

    @ViewBuilder private func manageSubscriptionView() -> some View {
        ListSection {
            ClickableRow {
                viewModel.onManageSubscriptions()
            } content: {
                HStack(spacing: .margin8) {
                    Text("subscription.manage".localized).textBody()
                    Spacer()
                    Image.disclosureIcon
                }
            }
        }
    }
}
