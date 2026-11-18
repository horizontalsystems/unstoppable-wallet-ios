import SwiftUI

struct SubscriptionView: View {
    @ObservedObject var viewModel: PurchasesViewModel

    var body: some View {
        PremiumFactory.background {
            ScrollView {
                VStack(spacing: .margin32) {
                    PremiumFactory.header(title: PremiumHeaderView.premiumTitle)
                    PremiumFeaturesListView(features: viewModel.features)
                    approvedBy()
                }
            }
            .safeAreaInset(edge: .bottom) {
                PremiumBottomContent {
                    actionButtonView()
                }
            }
        }
    }

    private func approvedBy() -> some View {
        LazyVGrid(columns: viewModel.approvedIcons.map { _ in GridItem(.flexible(), alignment: .center) }, spacing: .margin8) {
            ForEach(viewModel.approvedIcons, id: \.self) { icon in
                // Raster logos at their intrinsic size: ThemeImage either forces a square icon frame or drops the template tint
                Image(icon)
                    .renderingMode(.template)
                    .foregroundColor(.themeLeah)
            }
        }
        .frame(minHeight: .heightCell48)
        .padding(.horizontal, .margin24)
    }

    @ViewBuilder private func actionButtonView() -> some View {
        let (title, disabled) = buttonState()

        ThemeButton(text: title, style: .secondary, action: showPurchase)
            .disabled(disabled)
            .accessibilityIdentifier(TestTags.premiumSubscribe)
    }

    private func buttonState() -> (String, Bool) {
        var title = "purchases.button.try".localized
        var disabled = false

        switch viewModel.buttonState {
        case .tryForFree: ()
        case .activated:
            title = "purchases.button.activated".localized
            disabled = true
        case .upgrade:
            title = "purchases.button.upgrade".localized
            disabled = false
        }

        return (title, disabled)
    }

    private func showPurchase() {
        Coordinator.shared.present(type: .bottomSheet) { [weak viewModel] isPresented in
            PurchaseBottomSheetView(isPresented: isPresented) { _ in
                viewModel?.didSubscribeSuccessful()
            }
        }
    }
}
