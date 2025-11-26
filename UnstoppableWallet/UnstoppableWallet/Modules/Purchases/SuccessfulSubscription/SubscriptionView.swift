import SwiftUI

struct SubscriptionView: View {
    @StateObject var viewModel: PurchasesViewModel

    var body: some View {
        PremiumFactory.radialView {
            ScrollView {
                VStack(spacing: 0) {
                    PremiumFactory.header

                    PremiumFeaturesListView(categories: viewModel.viewItems)
                    walletDescription()
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomContent()
            }
        }
    }

    private func activatedDescription() -> some View {
        Text("purchases.successful_subscription.subscribed".localized)
            .textSubhead2(color: .themeJacob)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .margin32)
            .padding(.top, .margin12)
            .padding(.bottom, .margin32)
    }

    @ViewBuilder private func bottomContent() -> some View {
        VStack(spacing: .margin8) {
            actionButtonView()
        }
        .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        .background(
            CustomBlurView(removeAllFilters: false)
                .edgesIgnoringSafeArea(.bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        )
    }

    @ViewBuilder private func walletDescription() -> some View {
        VStack {
            Text("purchases.wallet_description.title".localized)
                .themeHeadline2(alignment: .center)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: .margin32, leading: .margin32, bottom: .margin24, trailing: .margin32))

            Image("premium_security")

            approvedBy()
        }
    }

    @ViewBuilder private func approvedBy() -> some View {
        VStack {
            Text("purchases.wallet_description.approved".localized)
                .textSubhead2()
                .multilineTextAlignment(.center)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin16)

            LazyVGrid(columns: viewModel.approvedIcons.map { _ in GridItem(.flexible(), alignment: .center) }, spacing: .margin8) {
                ForEach(viewModel.approvedIcons, id: \.self) { icon in
                    Image(icon)
                        .renderingMode(.template)
                        .foregroundColor(.themeLeah)
                }
            }
            .padding(.horizontal, .margin16)
        }
    }

    @ViewBuilder private func actionButtonView() -> some View {
        let (title, disabled) = buttonState()

        Button(action: {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                PurchaseBottomSheetView(isPresented: isPresented) { [weak viewModel] _ in
                    viewModel?.didSubscribeSuccessful()
                }
            }
        }) {
            Text(title)
        }
        .disabled(disabled)
        .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
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
}

struct CustomBlurView: UIViewRepresentable {
    let removeAllFilters: Bool

    func makeUIView(context _: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        DispatchQueue.main.async {
            if let backdropLayer = uiView.layer.sublayers?.first {
                if removeAllFilters {
                    backdropLayer.filters = []
                } else {
                    backdropLayer.filters?.removeAll(where: { filter in
                        String(describing: filter) != "gaussianBlur"
                    })
                }
            }
        }
    }
}
