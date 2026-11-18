import SwiftUI

struct PurchaseBottomSheetView: View {
    @StateObject private var viewModel: PurchaseBottomSheetViewModel

    @Binding private var isPresented: Bool
    @State private var redeemSheetPresented = false

    init(isPresented: Binding<Bool>, onSubscribe: @escaping @MainActor (PurchaseManager.ProductData) -> Void) {
        _viewModel = StateObject(wrappedValue: PurchaseBottomSheetViewModel(onSubscribe: onSubscribe))
        _isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            BSModule.view(for: .title(icon: nil, title: "purchase.period.title".localized))

            SubscribePeriodSegmentView(items: viewModel.items, selection: $viewModel.selectedItem) {
                redeemSheetPresented = true
            }
            .disabled(viewModel.buttonState == .loading)
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)

            ThemeText(footnote(), style: .subhead)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(TestTags.premiumPlansAgreement)
                .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin24, trailing: .margin32))

            ThemeButton(text: buttonTitle, spinner: viewModel.buttonState == .loading) {
                viewModel.subscribe()
            }
            .disabled(viewModel.buttonState == .loading)
            .accessibilityIdentifier(TestTags.premiumPlansSubscribe)
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
        }
        .onReceive(viewModel.finishPublisher) {
            isPresented = false
        }
        .offerCodeRedemption(isPresented: $redeemSheetPresented) { result in
            viewModel.handleRedeemCode(result: result)
        }
    }

    var subscriptionState: SubscriptionState {
        if viewModel.selectedItem?.product.type == .lifetime {
            return .lifetime
        } else if let offerType = viewModel.selectedItem?.introductoryOfferType {
            switch offerType {
            case .none: return .subscribe
            case .trial: return .freeTrial
            case .discount: return .discount
            }
        } else {
            return .subscribe
        }
    }

    var buttonTitle: String {
        switch subscriptionState {
        case .lifetime, .discount:
            return "purchases.period.button.buy".localized
        case .freeTrial:
            return "purchases.period.button.try".localized
        case .subscribe:
            return "purchases.period.button.subscribe".localized
        }
    }

    private func footnote() -> AttributedString {
        var result = AttributedString()

        switch subscriptionState {
        case .lifetime:
            result.append(textPart("purchase.lifetime.description".localized))
        case .freeTrial:
            result.append(textPart("purchase.period.description1".localized, color: .themeRemus))
            result.append(textPart(" "))
            result.append(textPart("purchase.period.description2".localized))
        case .discount:
            result.append(textPart("purchase.period.description1.1".localized, color: .themeRemus))
            result.append(textPart(" "))
            result.append(textPart("purchase.period.description2".localized))
        case .subscribe:
            result.append(textPart("purchase.period.description2".localized))
        }

        result.append(textPart(" "))
        result.append(termsText())

        return result
    }

    private func termsText() -> AttributedString {
        let string = "purchase.agree".localized
        let components = string.components(separatedBy: "%@")

        guard components.count == 3 else {
            return textPart(string)
        }

        var result = AttributedString("")

        if !components[0].isEmpty {
            result.append(textPart(components[0]))
        }
        result.append(textPart("purchase.agree.terms_of_service".localized, url: AppConfig.appleTermsOfServiceLink))
        if !components[1].isEmpty {
            result.append(textPart(components[1]))
        }
        result.append(textPart("purchase.agree.privacy_policy".localized, url: AppConfig.privacyPolicyLink))
        if !components[2].isEmpty {
            result.append(textPart(components[2]))
        }

        return result
    }

    private func textPart(_ string: String, color: Color = .themeGray, url: String? = nil) -> AttributedString {
        var part = AttributedString(string)
        part.foregroundColor = color

        if let url {
            part.link = URL(string: url)
            part.underlineStyle = .single
        }

        return part
    }
}

extension PurchaseBottomSheetView {
    enum SubscriptionState {
        case lifetime
        case freeTrial
        case discount
        case subscribe
    }
}
