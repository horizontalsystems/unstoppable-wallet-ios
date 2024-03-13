import ComponentKit
import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapConfirmationView: View {
    @StateObject private var viewModel: MultiSwapConfirmationViewModel
    @Binding private var swapPresentationMode: PresentationMode

    @State private var feeSettingsPresented = false

    init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, swapPresentationMode: Binding<PresentationMode>) {
        _viewModel = .init(wrappedValue: MultiSwapConfirmationViewModel(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider))
        _swapPresentationMode = swapPresentationMode
    }

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .quoting:
                VStack(spacing: .margin12) {
                    ProgressView()
                    Text("swap.confirmation.quoting".localized).textSubhead2()
                }
            case let .success(quote):
                quoteView(quote: quote)
            case let .failed(error):
                errorView(error: error)
            }
        }
        .sheet(isPresented: $feeSettingsPresented) {
            if let transactionService = viewModel.transactionService, let feeToken = viewModel.feeToken {
                transactionService.settingsView(
                    feeData: Binding<FeeData?>(get: { viewModel.state.quote?.feeData }, set: { _ in }),
                    loading: Binding<Bool>(get: { viewModel.state.isQuoting }, set: { _ in }),
                    feeToken: feeToken,
                    currency: viewModel.currency,
                    feeTokenRate: $viewModel.feeTokenRate
                )
            }
        }
        .navigationTitle("swap.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    feeSettingsPresented = true
                }) {
                    Image("manage_2_20").renderingMode(.template)
                }
                .disabled(viewModel.state.isQuoting)
            }
        }
        .onReceive(viewModel.errorSubject) { error in
            HudHelper.instance.showError(subtitle: error)
        }
    }

    @ViewBuilder private func quoteView(quote: IMultiSwapConfirmationQuote) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: .margin16) {
                    ListSection {
                        tokenRow(title: "swap.you_pay".localized, token: viewModel.tokenIn, amount: viewModel.amountIn, rate: viewModel.rateIn, type: .neutral)
                        tokenRow(title: "swap.you_get".localized, token: viewModel.tokenOut, amount: quote.amountOut, rate: viewModel.rateOut, type: .incoming)
                    }

                    let priceSectionFields = quote.priceSectionFields(
                        tokenIn: viewModel.tokenIn,
                        tokenOut: viewModel.tokenOut,
                        feeToken: viewModel.feeToken,
                        currency: viewModel.currency,
                        tokenInRate: viewModel.rateIn,
                        tokenOutRate: viewModel.rateOut,
                        feeTokenRate: viewModel.feeTokenRate
                    )

                    if viewModel.price != nil || !priceSectionFields.isEmpty {
                        ListSection {
                            if let price = viewModel.price {
                                ListRow {
                                    Text("swap.price".localized).textSubhead2()

                                    Spacer()

                                    Button(action: {
                                        viewModel.flipPrice()
                                    }) {
                                        HStack(spacing: .margin8) {
                                            Text(price)
                                                .textSubhead1(color: .themeLeah)
                                                .multilineTextAlignment(.trailing)

                                            Image("arrow_swap_3_20").themeIcon()
                                        }
                                    }
                                }
                            }

                            if !priceSectionFields.isEmpty {
                                ForEach(priceSectionFields.indices, id: \.self) { index in
                                    priceSectionFields[index].listRow
                                }
                            }
                        }
                    }

                    let otherSections = quote.otherSections(
                        tokenIn: viewModel.tokenIn,
                        tokenOut: viewModel.tokenOut,
                        feeToken: viewModel.feeToken,
                        currency: viewModel.currency,
                        tokenInRate: viewModel.rateIn,
                        tokenOutRate: viewModel.rateOut,
                        feeTokenRate: viewModel.feeTokenRate
                    )

                    if !otherSections.isEmpty {
                        ForEach(otherSections.indices, id: \.self) { sectionIndex in
                            let section = otherSections[sectionIndex]

                            if !section.isEmpty {
                                ListSection {
                                    ForEach(section.indices, id: \.self) { index in
                                        section[index].listRow
                                    }
                                }
                            }
                        }
                    }

                    let cautions = (viewModel.transactionService?.cautions ?? []) + quote.cautions(feeToken: viewModel.feeToken)

                    if !cautions.isEmpty {
                        VStack(spacing: .margin12) {
                            ForEach(cautions.indices, id: \.self) { index in
                                HighlightedTextView(caution: cautions[index])
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }

            if viewModel.quoteTimeLeft > 0 || viewModel.swapping {
                SlideButton(
                    styling: .text(
                        start: "swap.confirmation.slide_to_swap".localized,
                        end: "swap.confirmation.swapping".localized,
                        success: "swap.confirmation.swapped".localized
                    ),
                    action: {
                        try await viewModel.swap()
                    }, completion: {
                        HudHelper.instance.show(banner: .swapped)
                        swapPresentationMode.dismiss()
                    }
                )
                .padding(.vertical, .margin16)
                .padding(.horizontal, .margin16)
            } else {
                Button(action: {
                    viewModel.syncQuote()
                }) {
                    Text("swap.confirmation.refresh".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .gray))
                .padding(.vertical, .margin16)
                .padding(.horizontal, .margin16)
            }

            let (bottomText, bottomTextColor) = bottomText()

            Text(bottomText)
                .textSubhead1(color: bottomTextColor)
                .padding(.bottom, .margin8)
        }
    }

    @ViewBuilder private func errorView(error: Error) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: .margin16) {
                    HighlightedTextView(caution: CautionNew(text: error.smartDescription, type: .error))
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }

            Button(action: {
                viewModel.syncQuote()
            }) {
                Text("swap.confirmation.refresh".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .gray))
            .padding(.vertical, .margin16)
            .padding(.horizontal, .margin16)

            Text("swap.confirmation.quote_failed".localized)
                .textSubhead1()
                .padding(.bottom, .margin8)
        }
    }

    @ViewBuilder private func tokenRow(title: String, token: Token, amount: Decimal, rate: Decimal?, type: SendConfirmField.AmountType) -> some View {
        let field = SendConfirmField.amount(
            title: title,
            token: token,
            coinValueType: .regular(coinValue: CoinValue(kind: .token(token: token), value: amount)),
            currencyValue: rate.map { CurrencyValue(currency: viewModel.currency, value: amount * $0) },
            type: type
        )

        field.listRow
    }

    private func bottomText() -> (String, Color) {
        if let quote = viewModel.state.quote, !quote.canSwap {
            return ("swap.confirmation.invalid_quote".localized, .themeGray)
        } else if viewModel.swapping {
            return ("swap.confirmation.please_wait".localized, .themeGray)
        } else if viewModel.quoteTimeLeft > 0 {
            return ("swap.confirmation.quote_expires_in".localized("\(viewModel.quoteTimeLeft)"), .themeJacob)
        } else {
            return ("swap.confirmation.quote_expired".localized, .themeGray)
        }
    }
}
