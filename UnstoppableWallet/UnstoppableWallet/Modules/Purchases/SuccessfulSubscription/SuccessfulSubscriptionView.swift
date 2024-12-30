import SwiftUI

struct SuccessfulSubscriptionView: View {
    @StateObject private var viewModel = PurchasesViewModel()

    let type: PurchaseManager.SubscriptionType
    let onDismissPurchases: () -> Void

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                ThemeRadialView {
                    VStack {
                        Image("box_2")
                            .padding(.vertical, .margin24)

                        Text("purchases.successful_subscription.description".localized).textHeadline1(color: .themeLeah)
                            .frame(maxWidth: .infinity, alignment: .center)

                        activatedDescription(type: type)

                        if type == .vip {
                            VStack(spacing: 0) {
                                ListSection {
                                    ForEach(PurchasesViewModel.vipFeatures.map { ViewItem(feature: $0) }, id: \.self) { feature in
                                        row(
                                            title: "purchases.\(feature.title)".localized,
                                            image: Image(feature.iconName)
                                        )
                                    }
                                }
                                .themeListStyle(.steel10WithBottomCorners(.allCorners))
                            }
                            .padding(.bottom, .margin24)
                        }

                        Spacer()

                        VStack(spacing: .margin8) {
                            Button(action: {
                                onDismissPurchases()
                            }) {
                                Text("purchases.successful_subscription.button.go_app".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
                        }
                    }
                    .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
                }
                .navigationTitle("purchases.successful_subscription.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("button.close".localized) {
                            onDismissPurchases()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func activatedDescription(type: PurchaseManager.SubscriptionType) -> some View {
        (
            Text("purchases.successful_subscription.subscribed_to_1".localized + " ").foregroundColor(.themeGray).font(.themeSubhead2) +
                Text(type.rawValue.uppercased() + " ").foregroundColor(.themeJacob).font(.themeSubhead2) +
                Text("purchases.successful_subscription.subscribed_to_2".localized).foregroundColor(.themeGray).font(.themeSubhead2)
        )
        .multilineTextAlignment(.center)
        .padding(.horizontal, .margin8)
        .padding(.top, .margin12)
        .padding(.bottom, .margin32)
    }

    @ViewBuilder private func row(title: String, image: Image) -> some View {
        ListRow(padding: EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16)) {
            HStack(spacing: .margin16) {
                image
                    .renderingMode(.template)
                    .foregroundColor(.themeJacob)
                    .frame(width: 24, height: 24)

                Text(title).themeBody(color: .themeLeah)

                Image.disclosureIcon
            }
        }
    }
}

extension SuccessfulSubscriptionView {
    struct ViewItem: Hashable {
        let title: String
        let iconName: String

        init(feature: PurchasesViewModel.Feature) {
            title = feature.title
            iconName = feature.iconName
        }
    }
}
