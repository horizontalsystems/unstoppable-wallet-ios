import Foundation
import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapView: View {
    @StateObject var viewModel: MultiSwapViewModel
    private let onFinish: (() -> Void)?

    @State private var sendPresented = false
    @FocusState var isInputActive: Bool

    init(token: Token? = nil, onFinish: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: MultiSwapViewModel(token: token))
        self.onFinish = onFinish
    }

    var body: some View {
        ThemeView(style: .list) {
            BottomGradientWrapper(gradientColor: .themeLawrence) {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 0) {
                            amountsView()
                                .themeListTopView()

                            if let currentQuote = viewModel.currentQuote {
                                quoteView(quote: currentQuote)
                            } else {
                                availableBalanceView(value: balanceValue())
                            }
                        }

                        if let currentQuote = viewModel.currentQuote {
                            quoteCautionsView(quote: currentQuote)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .themeListScrollHeader()
                .onTapGesture {
                    isInputActive = false
                }
            } bottomContent: {
                buttonView()
            } keyboardContent: {
                if isInputActive {
                    AmountAccessoryView(
                        visible: isInputActive,
                        hasPercents: viewModel.availableBalance != nil,
                        onPercent: { percent in
                            viewModel.setAmountIn(percent: percent)
                            isInputActive = false
                        },
                        onTrash: {
                            viewModel.clearAmountIn()
                        }
                    )
                }
            }
            .animation(.easeOut(duration: 0.25), value: isInputActive)
        }
        .onAppear {
            viewModel.autoQuoteIfRequired()
        }
        .onDisappear {
            viewModel.stopAutoQuoting()
        }
        .navigationDestination(isPresented: $sendPresented) {
            if let tokenIn = viewModel.tokenIn,
               let tokenOut = viewModel.tokenOut,
               let amountIn = viewModel.amountIn,
               let currentQuote = viewModel.currentQuote
            {
                MultiSwapSendView(
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountIn,
                    provider: currentQuote.provider,
                    onFinish: onFinish ?? {
                        viewModel.reset()
                        sendPresented = false
                    }
                )
            }
        }
    }

    @ViewBuilder private func amountsView() -> some View {
        VStack(spacing: 8) {
            boxInView().padding(.horizontal, 16)
            boxSeparatorView()
            boxOutView().padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
        .background(Color.themeTyler)
    }

    @ViewBuilder private func boxInView() -> some View {
        HStack(spacing: 8) {
            selectorButton(token: viewModel.tokenIn) {
                Coordinator.shared.present { isPresented in
                    MultiSwapTokenSelectView(
                        title: "swap.you_pay".localized,
                        currentToken: $viewModel.tokenIn,
                        otherToken: viewModel.tokenOut,
                        isPresented: isPresented
                    )
                }
            }

            VStack(alignment: .trailing, spacing: 0) {
                TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.themeLeah)
                    .font(.themeHeadline1)
                    .tint(.themeInputFieldTintColor)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)
                    .frame(height: 33)

                if viewModel.tokenIn != nil {
                    if let coinPriceIn = viewModel.coinPriceIn {
                        HStack(spacing: 0) {
                            ThemeText(viewModel.currency.symbol, style: .body, colorStyle: viewModel.fiatAmountString.isEmpty ? .andy : .secondary)

                            TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeAndy))
                                .fixedSize(horizontal: true, vertical: false)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.themeGray)
                                .font(.themeBody)
                                .tint(.themeInputFieldTintColor)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .frame(height: 22)
                                .disabled(coinPriceIn.expired)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        ThemeText("n/a".localized, style: .body, colorStyle: .andy)
                            .frame(height: 22)
                    }
                } else {
                    ThemeText("\(viewModel.currency.symbol)0", style: .body, colorStyle: .andy)
                        .frame(height: 22)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder private func boxSeparatorView() -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.themeBlade)
                .frame(height: .heightOnePixel)
                .frame(maxWidth: .infinity)

            Button(action: {
                viewModel.interchange()
            }) {
                Image("arrow_medium_2_down_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))

            Rectangle()
                .fill(Color.themeBlade)
                .frame(height: .heightOnePixel)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func boxOutView() -> some View {
        HStack(spacing: 8) {
            selectorButton(token: viewModel.tokenOut) {
                Coordinator.shared.present { isPresented in
                    MultiSwapTokenSelectView(
                        title: "swap.you_get".localized,
                        currentToken: $viewModel.tokenOut,
                        otherToken: viewModel.tokenIn,
                        isPresented: isPresented
                    )
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                if let amountOutString = viewModel.amountOutString {
                    ThemeText(amountOutString, style: .headline1)
                        .lineLimit(1)
                } else {
                    ThemeText("0", style: .headline1, colorStyle: .secondary)
                }

                if viewModel.tokenOut != nil {
                    if viewModel.rateOut != nil {
                        HStack(spacing: 8) {
                            Spacer()

                            ThemeText("\(viewModel.currency.symbol)\((viewModel.fiatAmountOut ?? 0).description)", style: .body, colorStyle: viewModel.fiatAmountOut == nil ? .andy : .secondary)
                                .frame(height: 22)

                            if let priceImpact = viewModel.priceImpact {
                                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                                switch level {
                                case .negligible, .low:
                                    EmptyView()
                                default:
                                    ThemeText("(\(PriceImpact.display(value: priceImpact)))", style: .body, colorStyle: level.valueLevel.colorStyle)
                                }
                            }
                        }
                    } else {
                        ThemeText("n/a".localized, style: .body, colorStyle: .andy)
                            .frame(height: 22)
                    }
                } else {
                    ThemeText("\(viewModel.currency.symbol)0", style: .body, colorStyle: .andy)
                        .frame(height: 22)
                }
            }
        }
    }

    @ViewBuilder private func selectorButton(token: Token?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                CoinIconView(coin: token.map(\.coin))

                HStack(spacing: 8) {
                    if let token {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(token.coin.code).textHeadline1()
                            BadgeViewNew(token.fullBadge)
                        }
                    } else {
                        Text("swap.select".localized).textHeadline2(color: .themeJacob)
                    }

                    ThemeImage("arrow_s_down", size: 20, colorStyle: .secondary)
                }
            }
        }
    }

    @ViewBuilder private func buttonView() -> some View {
        let (title, style, disabled, showProgress, preSwapStep) = buttonState()

        ThemeButton(text: title, spinner: showProgress, style: style) {
            viewModel.stopAutoQuoting()

            if let preSwapStep {
                if let currentQuote = viewModel.currentQuote,
                   let tokenIn = viewModel.tokenIn,
                   let tokenOut = viewModel.tokenOut,
                   let amount = viewModel.amountIn
                {
                    Coordinator.shared.present { isPresented in
                        currentQuote.provider.preSwapView(
                            step: preSwapStep,
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            amount: amount,
                            isPresented: isPresented
                        ) {
                            viewModel.syncQuotes()
                        }

                    } onDismiss: {
                        viewModel.autoQuoteIfRequired()
                    }
                }
            } else if viewModel.shouldShowTerms {
                Coordinator.shared.present { isPresented in
                    SwapTermsView(isPresented: isPresented) {
                        viewModel.onAcceptTerms()

                        DispatchQueue.main.async {
                            isInputActive = false
                            sendPresented = true
                        }
                    }
                }
            } else {
                isInputActive = false
                sendPresented = true
            }
        }
        .disabled(disabled)
    }

    @ViewBuilder private func availableBalanceView(value: String?) -> some View {
        HStack(spacing: 8) {
            ThemeText("send.available_balance".localized, style: .subhead)
            Spacer()
            ThemeText(value ?? "----", style: .subheadSB)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
    }

    @ViewBuilder private func quoteView(quote: MultiSwapViewModel.Quote) -> some View {
        HStack(spacing: 4) {
            Button(action: {
                viewModel.stopAutoQuoting()

                Coordinator.shared.present { isPresented in
                    MultiSwapQuotesView(viewModel: viewModel, isPresented: isPresented)
                } onDismiss: {
                    viewModel.autoQuoteIfRequired()
                }
            }) {
                HStack(spacing: 8) {
                    Image(quote.provider.icon)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(4)
                        .frame(size: 24)

                    ThemeText(quote.provider.name, style: .subhead)

                    ThemeImage("arrow_s_down", size: 20)
                }
            }
            .layoutPriority(1)

            Spacer()

            if let price = viewModel.price {
                HStack {
                    ThemeText(price, style: .subheadSB, colorStyle: .primary)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .id(price)
                        .transition(.opacity)
                        .onTapGesture {
                            viewModel.flipPrice()
                        }
                }
                .animation(.easeInOut(duration: 0.15), value: price)
            }
        }
        .padding(16)
    }

    @ViewBuilder private func quoteCautionsView(quote: MultiSwapViewModel.Quote) -> some View {
        let cautions = quote.quote.cautions()

        if !cautions.isEmpty {
            ForEach(cautions.indices, id: \.self) { index in
                AlertCardView(caution: cautions[index])
            }
        }
    }

    private func balanceValue() -> String? {
        guard let availableBalance = viewModel.availableBalance, let tokenIn = viewModel.tokenIn else {
            return nil
        }

        return AppValue(token: tokenIn, value: availableBalance).formattedFull()
    }

    private func buttonState() -> (String, ThemeButton.Style, Bool, Bool, MultiSwapPreSwapStep?) {
        let title: String
        var style: ThemeButton.Style = .primary
        var disabled = true
        var showProgress = false
        var preSwapStep: MultiSwapPreSwapStep?

        if viewModel.quoting {
            title = "swap.quoting".localized
            showProgress = true
        } else if viewModel.tokenIn == nil {
            title = "swap.select_token_in".localized
        } else if viewModel.tokenOut == nil {
            title = "swap.select_token_out".localized
        } else if viewModel.validProviders.isEmpty {
            title = "swap.no_providers".localized
        } else if viewModel.amountIn == nil {
            title = "swap.enter_amount".localized
        } else if viewModel.currentQuote == nil {
            title = "swap.no_quotes".localized
        } else if viewModel.adapterState == nil {
            title = "swap.token_not_enabled".localized
        } else if let adapterState = viewModel.adapterState, adapterState.syncing, !viewModel.spendMode.spendAllowed(state: adapterState) {
            title = "swap.token_syncing".localized
            showProgress = true
        } else if let adapterState = viewModel.adapterState, !viewModel.spendMode.spendAllowed(state: adapterState) {
            title = "swap.token_not_synced".localized
        } else if let availableBalance = viewModel.availableBalance, let amountIn = viewModel.amountIn, amountIn > availableBalance {
            title = "swap.insufficient_balance".localized
        } else if let currentQuote = viewModel.currentQuote, let state = currentQuote.quote.customButtonState {
            title = state.title
            style = state.style
            disabled = state.disabled
            showProgress = state.showProgress
            preSwapStep = state.preSwapStep
        } else {
            title = "swap.proceed_button".localized
            disabled = false
        }

        return (title, style, disabled, showProgress, preSwapStep)
    }
}
