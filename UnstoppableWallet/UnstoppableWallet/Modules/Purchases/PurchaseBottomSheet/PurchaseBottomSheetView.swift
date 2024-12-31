import Chart
import MarketKit
import SwiftUI

struct PurchaseBottomSheetView: View {
    @StateObject private var viewModel: PurchaseBottomSheetViewModel

    @Binding private var isPresented: Bool
    @State private var isPresentedPromoCode: Bool = false

    private let onSubscribe: (PurchaseManager.SubscriptionPeriod) -> Void

    init(type: PurchaseManager.SubscriptionType, isPresented: Binding<Bool>, onSubscribe: @escaping (PurchaseManager.SubscriptionPeriod) -> Void) {
        _viewModel = StateObject(wrappedValue: PurchaseBottomSheetViewModel(type: type, onSubscribe: onSubscribe))
        self.onSubscribe = onSubscribe
        _isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image(viewModel.type.icon).themeIcon(color: .themeJacob)
                Text(viewModel.type.rawValue.uppercased()).themeHeadline2()

                Button(action: {
                    isPresented = false
                }) {
                    Image("close_3_24")
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin12)

            SubscribePeriodSegmentView(type: viewModel.type, selection: $viewModel.selectedPeriod)
                .onChange(of: viewModel.selectedPeriod) { newValue in
                    viewModel.set(period: newValue)
                }
                .padding(.top, .margin12)
                .padding(.horizontal, .margin16)

            tryFreeDescription()
                .padding(.horizontal, .margin16)

            VStack(spacing: .margin12) {
                Button(action: {
                    viewModel.subscribe()
                }) {
                    HStack(spacing: .margin8) {
                        if viewModel.buttonState == .loading {
                            ProgressView()
                        }
                        Text("purchases.period.button.try".localized)
                    }
                }
                .disabled(viewModel.buttonState == .loading)
                .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))

                Button(action: {
                    isPresentedPromoCode = true
                }) {
                    Text("purchases.period.button.promo".localized)
                }
                .disabled(viewModel.buttonState == .loading)
                .buttonStyle(PrimaryButtonStyle(style: .transparent))
            }
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
        .bottomSheet(
            isPresented: $isPresentedPromoCode,
            configuration: ActionSheetConfiguration(style: .sheet)
                .set(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
                .set(focusFirstTextField: true)
                .set(contentBackgroundColor: .themeLawrence)
        ) {
            PromoCodeBottomSheetView(promo: viewModel.promoData.promocode, isPresented: Binding(get: { isPresentedPromoCode }, set: { isPresentedPromoCode = $0 })) { data in
                viewModel.set(promoData: data)
            }
        }
    }

    private func tryFreeDescription() -> some View {
        (
            Text("purchase.period.description1".localized + " ").foregroundColor(.themeRemus).font(.themeSubhead2) +
                Text("purchase.period.description2".localized).foregroundColor(.themeGray).font(.themeSubhead2)
        )
        .multilineTextAlignment(.center)
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin12)
    }
}