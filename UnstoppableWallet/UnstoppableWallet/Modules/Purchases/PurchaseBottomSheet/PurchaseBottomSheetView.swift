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

            VStack(spacing: 0) {
                subscribedDescription().multilineTextAlignment(.center)
                Spacer()
            }
            .frame(height: 64)
            .padding(.top, .margin12)
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
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: 0, trailing: .margin24))

            VStack(spacing: 0) {
                Text(termsText())
                    .foregroundColor(.themeGray)
                    .font(.themeSubhead2)
                    .multilineTextAlignment(.center)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin12, trailing: .margin32))
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

    private func termsText() -> AttributedString {
        let string = "purchase.agree".localized
        let components = string.components(separatedBy: "%@")

        guard components.count == 3 else {
            return AttributedString(string)
        }

        var result = AttributedString("")

        if !components[0].isEmpty { result.append(termsTextPart(string: components[0])) }
        result.append(termsTextPart(string: "purchase.agree.terms_of_service".localized, url: AppConfig.appleTermsOfServiceLink))
        if !components[1].isEmpty { result.append(termsTextPart(string: components[1])) }
        result.append(termsTextPart(string: "purchase.agree.privacy_policy".localized, url: AppConfig.privacyPolicyLink))
        if !components[2].isEmpty { result.append(termsTextPart(string: components[2])) }

        return result
    }

    private func termsTextPart(string: String, url: String? = nil) -> AttributedString {
        var part = AttributedString(string)

        if let url {
            part.link = URL(string: url)
            part.foregroundColor = .themeGray
            part.underlineStyle = .single
        }

        return part
    }
}

extension PurchaseBottomSheetView {
    enum SubscriptionState {
        case lifetime
        case freeTrial
        case subscribe
    }
}
