import Foundation
import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapView: View {
    @StateObject var viewModel: MultiSwapViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var sendPresented = false

    @FocusState var isInputActive: Bool

    @State private var shouldPresentTokenIn: Bool

    init(token: Token? = nil) {
        _viewModel = StateObject(wrappedValue: MultiSwapViewModel.instance(token: token))
        shouldPresentTokenIn = token == nil
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                ScrollView {
                    VStack(spacing: 12) {
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                amountsView()
                                availableBalanceView(value: balanceValue())
                            }

                            buttonView()
                        }

                        if let currentQuote = viewModel.currentQuote, let tokenIn = viewModel.tokenIn, let tokenOut = viewModel.tokenOut {
                            quoteView(currentQuote: currentQuote, tokenIn: tokenIn, tokenOut: tokenOut)
                            quoteCautionsView(currentQuote: currentQuote)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 32, trailing: 16))
                }
            }
            .navigationTitle("swap.title".localized)
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
                        slippage: viewModel.slippage,
                        provider: currentQuote.provider,
                        swapPresentationMode: presentationMode
                    )
                }
            }
            .onChange(of: sendPresented) { presented in
                if !presented {
                    viewModel.autoQuoteIfRequired()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO:
                    }) {
                        Image("manage")
                    }
                }
            }
        }
        .onAppear {
            if shouldPresentTokenIn {
                presentTokenIn()
                shouldPresentTokenIn = false
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
        .modifier(ThemeListStyleModifier(cornerRadius: 16))
    }

    @ViewBuilder private func boxInView() -> some View {
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                    .foregroundColor(.themeLeah)
                    .font(.themeTitle3)
                    .tint(.themeInputFieldTintColor)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)
                    .frame(height: 33)

                if viewModel.tokenIn != nil {
                    if let coinPriceIn = viewModel.coinPriceIn {
                        HStack(spacing: 0) {
                            Text(viewModel.currency.symbol).textBody(color: viewModel.fiatAmountString.isEmpty ? .themeAndy : .themeGray)

                            TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeAndy))
                                .foregroundColor(.themeGray)
                                .font(.themeBody)
                                .tint(.themeInputFieldTintColor)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .frame(height: 22)
                                .disabled(coinPriceIn.expired)
                        }
                    } else {
                        Text("n/a".localized)
                            .themeBody(color: .themeAndy)
                            .frame(height: 22)
                    }
                } else {
                    Text("\(viewModel.currency.symbol)0")
                        .themeBody(color: .themeAndy)
                        .frame(height: 22)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isInputActive {
                        HStack(spacing: 0) {
                            if viewModel.availableBalance != nil {
                                ForEach(1 ... 4, id: \.self) { multiplier in
                                    let percent = multiplier * 25

                                    Button(action: {
                                        viewModel.setAmountIn(percent: percent)
                                        isInputActive = false
                                    }) {
                                        Text("\(percent)%").textSubhead1(color: .themeLeah)
                                    }
                                    .frame(maxWidth: .infinity)

                                    RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                                        .fill(Color.themeBlade)
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                            } else {
                                Spacer()
                            }

                            Button(action: {
                                viewModel.clearAmountIn()
                            }) {
                                Image(systemName: "trash")
                                    .font(.themeSubhead1)
                                    .foregroundColor(.themeLeah)
                            }
                            .frame(maxWidth: .infinity)

                            RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                                .fill(Color.themeBlade)
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)

                            Button(action: {
                                isInputActive = false
                            }) {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .font(.themeSubhead1)
                                    .foregroundColor(.themeLeah)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, -16)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            Spacer()

            selectorButton(token: viewModel.tokenIn) {
                presentTokenIn()
            }
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
            VStack(spacing: 0) {
                if let amountOutString = viewModel.amountOutString {
                    Text(amountOutString)
                        .themeTitle3()
                        .lineLimit(1)
                } else {
                    Text("0").themeTitle3(color: .themeGray)
                }

                if viewModel.tokenOut != nil {
                    if viewModel.rateOut != nil {
                        HStack(spacing: 8) {
                            Text("\(viewModel.currency.symbol)\((viewModel.fiatAmountOut ?? 0).description)")
                                .textBody(color: viewModel.fiatAmountOut == nil ? .themeAndy : .themeGray)
                                .frame(height: 22)

                            if let priceImpact = viewModel.priceImpact {
                                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                                switch level {
                                case .negligible:
                                    EmptyView()
                                default:
                                    Text("(\(priceImpact.rounded(decimal: 2).description)%)")
                                        .textBody(color: color(valueLevel: level.valueLevel))
                                }
                            }

                            Spacer()
                        }
                    } else {
                        Text("n/a".localized)
                            .themeBody(color: .themeAndy)
                            .frame(height: 22)
                    }
                } else {
                    Text("\(viewModel.currency.symbol)0")
                        .themeBody(color: .themeAndy)
                        .frame(height: 22)
                }
            }

            Spacer()

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
        }
    }

    @ViewBuilder private func selectorButton(token: Token?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                CoinIconView(coin: token.map(\.coin))

                if let token {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(token.coin.code).textHeadline2()
                        Text(token.fullBadge).textSubhead1()
                    }
                } else {
                    Text("swap.select".localized).textHeadline2(color: .themeJacob)
                }

                Image("arrow_small_down_20").themeIcon(color: .themeGray)
            }
        }
    }

    private func color(valueLevel: ValueLevel) -> Color {
        switch valueLevel {
        case .regular: return .themeLeah
        case .warning: return .themeJacob
        case .error: return .themeLucian
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
            } else {
                sendPresented = true
            }
        }
        .disabled(disabled)
    }

    @ViewBuilder private func availableBalanceView(value: String?) -> some View {
        HStack(spacing: 8) {
            Text("send.available_balance".localized).textCaptionSB()
            Spacer()
            Text(value ?? "---")
                .textCaption()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder private func quoteView(currentQuote: MultiSwapViewModel.Quote, tokenIn: Token, tokenOut: Token) -> some View {
        ListSection {
            providerView(currentQuote: currentQuote, tokenIn: tokenIn, tokenOut: tokenOut)

            if let price = viewModel.price {
                priceView(value: price)
                    .padding(.vertical, 8)
            }
        }
        .themeListStyle(.bordered)
    }

    @ViewBuilder private func quoteCautionsView(currentQuote: MultiSwapViewModel.Quote) -> some View {
        let cautions = currentQuote.quote.cautions() + cautions(quote: currentQuote)

        if !cautions.isEmpty {
            ForEach(cautions.indices, id: \.self) { index in
                AlertCardView(caution: cautions[index])
            }
        }
    }

    @ViewBuilder private func providerView(currentQuote: MultiSwapViewModel.Quote, tokenIn _: Token, tokenOut _: Token) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                viewModel.stopAutoQuoting()

                Coordinator.shared.present { isPresented in
                    MultiSwapQuotesView(viewModel: viewModel, isPresented: isPresented)
                } onDismiss: {
                    viewModel.autoQuoteIfRequired()
                }
            }) {
                HStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Image(currentQuote.provider.icon)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(4)
                            .frame(width: .iconSize24, height: .iconSize24)

                        Text(currentQuote.provider.name).textSubhead1()
                    }

                    ThemeImage("arrow_small_down", size: 20)
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 12))
    }

    @ViewBuilder private func priceView(value: String) -> some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: "swap.price".localized)
            },
            right: {
                RightTextIcon(text: value)
                    .id(value)
                    .transition(.opacity)
                    .onTapGesture {
                        viewModel.flipPrice()
                    }
            }
        )
        .animation(.easeInOut(duration: 0.15), value: value)
    }

    private func balanceValue() -> String? {
        guard let availableBalance = viewModel.availableBalance, let tokenIn = viewModel.tokenIn else {
            return nil
        }

        return AppValue(token: tokenIn, value: availableBalance).formattedFull()
    }

    private func cautions(quote: MultiSwapViewModel.Quote) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let priceImpact = viewModel.priceImpact {
            let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

            switch level {
            case .forbidden: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized(AppConfig.appName, quote.provider.name), type: .error))
            default: ()
            }
        }

        return cautions
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
        } else if let adapterState = viewModel.adapterState, adapterState.syncing {
            title = "swap.token_syncing".localized
            showProgress = true
        } else if let adapterState = viewModel.adapterState, !adapterState.isSynced {
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

    private func presentTokenIn() {
        Coordinator.shared.present { isPresented in
            MultiSwapTokenSelectView(
                title: "swap.you_pay".localized,
                currentToken: $viewModel.tokenIn,
                otherToken: viewModel.tokenOut,
                isPresented: isPresented
            )
        }
    }
}
