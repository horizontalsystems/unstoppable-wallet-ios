import Chart
import MarketKit
import SwiftUI

struct PurchaseBottomSheetView: View {
    @StateObject private var viewModel: PurchaseBottomSheetViewModel

    @Binding private var isPresented: Bool
    @State private var redeemSheetPresented = false

    init(isPresented: Binding<Bool>, onSubscribe: @escaping (PurchaseManager.ProductData) -> Void) {
        _viewModel = StateObject(wrappedValue: PurchaseBottomSheetViewModel(onSubscribe: onSubscribe))
        _isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image("circle_clock_24").themeIcon(color: .themeJacob)
                Text("purchase.period.title".localized).themeHeadline2()

                Button(action: {
                    isPresented = false
                }) {
                    Image("close_3_24")
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin12)

            SubscribePeriodSegmentView(items: $viewModel.items, selection: $viewModel.selectedItem)
                .onChange(of: viewModel.selectedItem) { newValue in
                    if let newValue {
                        viewModel.set(item: newValue)
                    }
                }
                .padding(.top, .margin12)
                .padding(.horizontal, .margin16)

            subscribedDescription()
                .multilineTextAlignment(.center)
                .frame(height: 64)
                .padding(.horizontal, .margin32)

            VStack(spacing: .margin12) {
                Button(action: {
                    viewModel.subscribe()
                }) {
                    HStack(spacing: .margin8) {
                        if viewModel.buttonState == .loading {
                            ProgressView()
                        }
                        Text(buttonTitle)
                    }
                }
                .disabled(viewModel.buttonState == .loading)
                .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))

                Button(action: {
                    redeemSheetPresented = true
                }) {
                    Text("purchases.period.button.promo".localized)
                }
                .disabled(viewModel.buttonState == .loading)
                .buttonStyle(PrimaryButtonStyle(style: .transparent))
            }
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
        .offerCodeRedemption(isPresented: $redeemSheetPresented) { result in
            viewModel.handleRedeemCode(result: result)
        }
    }

    var subscriptionState: SubscriptionState {
        if viewModel.selectedItem?.product.type == .lifetime {
            return .lifetime
        } else if viewModel.allowTrialPeriod, viewModel.selectedItem?.product.hasTrialPeriod == true {
            return .freeTrial
        } else {
            return .subscribe
        }
    }

    var buttonTitle: String {
        switch subscriptionState {
        case .lifetime:
            return "purchases.period.button.buy".localized
        case .freeTrial:
            return "purchases.period.button.try".localized
        case .subscribe:
            return "purchases.period.button.subscribe".localized
        }
    }

    @ViewBuilder private func subscribedDescription() -> some View {
        switch subscriptionState {
        case .lifetime:
            Text("purchase.lifetime.description").foregroundColor(.themeGray).font(.themeSubhead2)

        case .freeTrial:
            Text("purchase.period.description1".localized + " ").foregroundColor(.themeRemus).font(.themeSubhead2) +
                Text("purchase.period.description2".localized).foregroundColor(.themeGray).font(.themeSubhead2)

        case .subscribe:
            Text("purchase.period.description2".localized).foregroundColor(.themeGray).font(.themeSubhead2)
        }
    }
}

extension PurchaseBottomSheetView {
    enum SubscriptionState {
        case lifetime
        case freeTrial
        case subscribe
    }
}
