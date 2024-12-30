import Kingfisher
import MarketKit
import SwiftUI

struct PurchaseListView: View {
    @ObservedObject private var viewModel = PurchaseListViewModel()

    @State private var presentedSubscription: PurchaseManager.Subscription?

    var body: some View {
        ScrollableThemeView {
            VStack {
                if let subscription = viewModel.subscription {
                    ListSection {
                        row(value: subscription.type.rawValue.uppercased()) {
                            presentedSubscription = subscription
                        }
                    }

                    footerDescription(timestamp: subscription.timestamp)
                } else {
                    Text("subscription.no_purchases".localized)
                        .multilineTextAlignment(.center)
                        .textSubhead2()
                        .padding(.horizontal, .margin32)
                        .padding(.vertical, .margin12)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .sheet(item: $presentedSubscription) { _ in
            PurchasesView()
        }
        .navigationTitle("subscription.title".localized)
    }

    @ViewBuilder private func row(value: String, action: @escaping () -> Void) -> some View {
        ClickableRow(padding: EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), action: action) {
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

    private func footerDescription(timestamp: TimeInterval) -> some View {
        let date = DateHelper.instance.formatShortDateOnly(date: Date(timeIntervalSince1970: timestamp))

        return (
            Text("subscription.footer_description_1".localized(date)).foregroundColor(.themeGray).font(.themeSubhead2) +
                Text("subscription.footer_description_2".localized)
                .foregroundColor(.themeJacob)
                .font(.themeSubhead2)
                .underline(color: .themeJacob) +
                Text("subscription.footer_description_3".localized).foregroundColor(.themeGray).font(.themeSubhead2)
        )
        .multilineTextAlignment(.leading)
        .onTapGesture(perform: {
            viewModel.onManageSubscriptions()
        })
        .padding(.horizontal, .margin32)
        .padding(.vertical, .margin12)
    }
}
