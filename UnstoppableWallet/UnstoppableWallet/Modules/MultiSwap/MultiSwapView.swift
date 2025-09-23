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
                    VStack(spacing: .margin12) {
                        VStack(spacing: .margin16) {
                            VStack(spacing: .margin8) {
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
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
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
                    if let nextQuoteTime = viewModel.nextQuoteTime {
                        MultiSwapCircularProgressView(nextQuoteTime: nextQuoteTime, autoRefreshDuration: viewModel.autoRefreshDuration)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
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
        VStack(spacing: .margin8) {
            boxInView().padding(.horizontal, .margin16)
            boxSeparatorView()
            boxOutView().padding(.horizontal, .margin16)
        }
        .padding(.vertical, 20)
        .modifier(ThemeListStyleModifier(cornerRadius: 18))
    }

    @ViewBuilder private func boxInView() -> some View {
        HStack(spacing: .margin8) {
            VStack(spacing: 3) {
                TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                    .foregroundColor(.themeLeah)
                    .font(.themeHeadline1)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)

                if viewModel.tokenIn != nil {
                    if let coinPriceIn = viewModel.coinPriceIn {
                        HStack(spacing: 0) {
                            Text(viewModel.currency.symbol).textBody(color: .themeGray)

                            TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeGray))
                                .foregroundColor(.themeGray)
                                .font(.themeBody)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .frame(height: 20)
                                .disabled(coinPriceIn.expired)
                        }
                    } else {
                        Text("swap.rate_not_available".localized)
                            .themeSubhead2(color: .themeGray50, alignment: .leading)
                            .frame(height: 20)
                    }
                } else {
                    Text("\(viewModel.currency.symbol)0")
                        .themeBody(color: .themeGray50, alignment: .leading)
                        .frame(height: 20)
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
                .frame(height: .heightOneDp)
                .frame(maxWidth: .infinity)

            Button(action: {
                viewModel.interchange()
            }) {
                Image("arrow_medium_2_down_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))

            Rectangle()
                .fill(Color.themeBlade)
                .frame(height: .heightOneDp)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func boxOutView() -> some View {
        HStack(spacing: .margin8) {
            VStack(spacing: 3) {
                if let amountOutString = viewModel.amountOutString {
                    Text(amountOutString)
                        .themeHeadline1(color: .themeLeah, alignment: .leading)
                        .lineLimit(1)
                } else {
                    Text("0").themeHeadline1(color: .themeGray, alignment: .leading)
                }

                if viewModel.tokenOut != nil {
                    if viewModel.rateOut != nil {
                        HStack(spacing: .margin8) {
                            Text("\(viewModel.currency.symbol)\((viewModel.fiatAmountOut ?? 0).description)")
                                .textBody(color: .themeGray)
                                .frame(height: 20)

                            if let priceImpact = viewModel.priceImpact, priceImpact < 0 {
                                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                                switch level {
                                case .negligible:
                                    EmptyView()
                                default:
                                    Text("(\(priceImpact.rounded(decimal: 2).description)%)")
                                        .textSubhead1(color: color(valueLevel: level.valueLevel))
                                }
                            }

                            Spacer()
                        }
                    } else {
                        Text("swap.rate_not_available".localized)
                            .themeSubhead2(color: .themeGray50, alignment: .leading)
                            .frame(height: 20)
                    }
                } else {
                    Text("\(viewModel.currency.symbol)0")
                        .themeBody(color: .themeGray50, alignment: .leading)
                        .frame(height: 20)
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
            HStack(spacing: .margin8) {
                CoinIconView(coin: token.map(\.coin))

                if let token {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(token.coin.code).textSubhead1(color: .themeLeah)
                        Text(token.fullBadge).textMicro()
                    }
                } else {
                    Text("swap.select".localized).textSubhead1(color: .themeJacob)
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

        Button(action: {
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
        }) {
            HStack(spacing: .margin8) {
                if showProgress {
                    ProgressView()
                }

                Text(title)
            }
        }
        .disabled(disabled)
        .buttonStyle(PrimaryButtonStyle(style: style))
    }

    @ViewBuilder private func availableBalanceView(value: String?) -> some View {
        HStack(spacing: .margin8) {
            Text("send.available_balance".localized).textCaption()
            Spacer()
            Text(value ?? "---")
                .textCaption()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, .margin16)
    }

    @ViewBuilder private func quoteView(currentQuote: MultiSwapViewModel.Quote, tokenIn: Token, tokenOut: Token) -> some View {
        ListSection {
            providerView(currentQuote: currentQuote, tokenIn: tokenIn, tokenOut: tokenOut)

            VStack(spacing: 0) {
                if let price = viewModel.price {
                    priceView(value: price)
                }

                let fields = currentQuote.quote.fields(
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    currency: viewModel.currency,
                    tokenInRate: viewModel.coinPriceIn?.value,
                    tokenOutRate: viewModel.rateOut
                )

                if !fields.isEmpty {
                    ForEach(fields) { field in
                        providerFieldView(field: field)
                    }
                }
            }
        }
        .themeListStyle(.bordered)
    }

    @ViewBuilder private func quoteCautionsView(currentQuote: MultiSwapViewModel.Quote) -> some View {
        let cautions = currentQuote.quote.cautions()

        if !cautions.isEmpty {
            ForEach(cautions.indices, id: \.self) { index in
                HighlightedTextView(caution: cautions[index])
            }
        }
    }

    @ViewBuilder private func providerView(currentQuote: MultiSwapViewModel.Quote, tokenIn: Token, tokenOut: Token) -> some View {
        HStack(spacing: .margin8) {
            Button(action: {
                viewModel.stopAutoQuoting()

                Coordinator.shared.present { isPresented in
                    MultiSwapQuotesView(viewModel: viewModel, isPresented: isPresented)
                } onDismiss: {
                    viewModel.autoQuoteIfRequired()
                }
            }) {
                HStack(spacing: .margin8) {
                    Image(currentQuote.provider.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: .iconSize24, height: .iconSize24)

                    Text(currentQuote.provider.name).textSubhead1(color: .themeLeah)
                    Image("arrow_small_down_20").themeIcon(color: .themeGray)
                }
            }

            Spacer()

            Button(action: {
                viewModel.stopAutoQuoting()

                Coordinator.shared.present { _ in
                    currentQuote.provider.settingsView(tokenIn: tokenIn, tokenOut: tokenOut, quote: currentQuote.quote) {
                        viewModel.syncQuotes()
                    }
                } onDismiss: {
                    viewModel.autoQuoteIfRequired()
                }
            }) {
                if currentQuote.quote.settingsModified {
                    Image("manage_2_20").themeIcon(color: .themeJacob)
                } else {
                    Image("manage_2_20").renderingMode(.template)
                }
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin12))
        .frame(minHeight: 40)
    }

    @ViewBuilder private func priceView(value: String) -> some View {
        HStack(spacing: .margin8) {
            Text("swap.price".localized).textSubhead2()

            Spacer()

            Button(action: {
                viewModel.flipPrice()
            }) {
                HStack(spacing: .margin8) {
                    Text(value)
                        .textSubhead2(color: .themeLeah)
                        .multilineTextAlignment(.trailing)

                    Image("arrow_swap_3_20").themeIcon()
                }
            }
        }
        .padding(.vertical, .margin12)
        .padding(.horizontal, .margin16)
        .frame(minHeight: 40)
    }

    @ViewBuilder private func providerFieldView(field: MultiSwapMainField) -> some View {
        HStack(spacing: .margin8) {
            if let infoDescription = field.infoDescription {
                Text(field.title)
                    .textSubhead2()
                    .modifier(Informed(infoDescription: infoDescription))
            } else {
                Text(field.title)
                    .textSubhead2()
            }

            Spacer()

            Text(field.value)
                .textSubhead2(color: color(valueLevel: field.valueLevel))
                .multilineTextAlignment(.trailing)

            if let settingId = field.settingId {
                Button(action: {
                    if let tokenOut = viewModel.tokenOut, let currentQuote = viewModel.currentQuote {
                        Coordinator.shared.present { _ in
                            currentQuote.provider.settingView(settingId: settingId, tokenOut: tokenOut) {
                                viewModel.syncQuotes()
                            }
                        }
                    }
                }) {
                    if field.modified {
                        Image("pen_filled").themeIcon(color: .themeJacob)
                    } else {
                        Image("pen_filled").renderingMode(.template)
                    }
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
            }
        }
        .padding(.vertical, .margin12)
        .padding(.leading, field.infoDescription == nil ? .margin16 : 0)
        .padding(.trailing, field.settingId == nil ? .margin16 : .margin12)
        .frame(minHeight: 40)
    }

    private func balanceValue() -> String? {
        guard let availableBalance = viewModel.availableBalance, let tokenIn = viewModel.tokenIn else {
            return nil
        }

        return AppValue(token: tokenIn, value: availableBalance).formattedFull()
    }

    private func buttonState() -> (String, PrimaryButtonStyle.Style, Bool, Bool, MultiSwapPreSwapStep?) {
        let title: String
        var style: PrimaryButtonStyle.Style = .yellow
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

    func presentTokenIn() {
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
