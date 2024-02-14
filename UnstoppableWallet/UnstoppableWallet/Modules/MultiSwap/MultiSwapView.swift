import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapView: View {
    @ObservedObject var viewModel: MultiSwapViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var selectTokenInPresented = false
    @State private var selectTokenOutPresented = false
    @State private var quotesPresented = false
    @State private var confirmPresented = false
    @State private var settingsPresented = false
    @State private var feeSettingsPresented = false
    @State private var preSwapStepId: String?
    @State private var presentedSettingId: String?

    @FocusState var isInputActive: Bool

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                ScrollView {
                    VStack(spacing: .margin12) {
                        amountsView()
                        buttonView()

                        if let balanceValue = balanceValue() {
                            availableBalanceView(value: balanceValue)
                        }

                        if let currentQuote = viewModel.currentQuote, let tokenIn = viewModel.tokenIn, let tokenOut = viewModel.tokenOut {
                            quoteView(currentQuote: currentQuote, tokenIn: tokenIn, tokenOut: tokenOut)
                            quoteCautionsView(currentQuote: currentQuote)
                            transactionServiceCautionsView()
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    .sheet(isPresented: $quotesPresented, onDismiss: { viewModel.autoQuoteIfRequired() }) {
                        MultiSwapQuotesView(viewModel: viewModel, isPresented: $quotesPresented)
                    }
                    .sheet(isPresented: $feeSettingsPresented, onDismiss: { viewModel.autoQuoteIfRequired() }) {
                        if let feeService = viewModel.transactionService {
                            feeService.settingsView { viewModel.syncQuotes() }
                        }
                    }
                    .sheet(item: $preSwapStepId, onDismiss: { viewModel.autoQuoteIfRequired() }) { stepId in
                        if let currentQuote = viewModel.currentQuote {
                            currentQuote.provider.preSwapView(stepId: stepId)
                        }
                    }
                }

                if let tokenIn = viewModel.tokenIn, let tokenOut = viewModel.tokenOut, let amountIn = viewModel.amountIn, let currentQuote = viewModel.currentQuote, let transactionService = viewModel.transactionService {
                    NavigationLink(
                        destination: MultiSwapConfirmationView(
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            amountIn: amountIn,
                            provider: currentQuote.provider,
                            transactionService: transactionService,
                            isPresented: $confirmPresented
                        ),
                        isActive: $confirmPresented
                    ) {
                        EmptyView()
                    }
                    .onChange(of: confirmPresented) { presented in
                        if !presented {
                            viewModel.autoQuoteIfRequired()
                        }
                    }
                }
            }
            .navigationTitle("swap.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if let nextQuoteTime = viewModel.nextQuoteTime {
                        MultiSwapCircularProgressView(nextQuoteTime: nextQuoteTime, autoRefreshDuration: viewModel.autoRefreshDuration)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.stopAutoQuoting()
                        feeSettingsPresented = true
                    }) {
                        Image("manage_2_20").renderingMode(.template)
                    }
                    .disabled(viewModel.transactionService == nil)
                }
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
        .modifier(ThemeListStyleModifier(themeListStyle: .lawrence))
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
                    if viewModel.rateIn != nil {
                        HStack(spacing: 0) {
                            Text(viewModel.currency.symbol).textBody(color: .themeGray)

                            TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeGray))
                                .foregroundColor(.themeGray)
                                .font(.themeBody)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .frame(height: 20)
                        }
                    } else {
                        Text("Rate not available")
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
                                        .fill(Color.themeSteel20)
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                            } else {
                                Spacer()
                            }

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
                selectTokenInPresented = true
            }
            .sheet(isPresented: $selectTokenInPresented) {
                MultiSwapTokenSelectView(token: $viewModel.tokenIn, isPresented: $selectTokenInPresented)
            }
        }
    }

    @ViewBuilder private func boxSeparatorView() -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.themeSteel20)
                .frame(height: .heightOneDp)
                .frame(maxWidth: .infinity)

            Button(action: {
                viewModel.interchange()
            }) {
                Image("arrow_medium_2_down_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))

            Rectangle()
                .fill(Color.themeSteel20)
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
                        Text("Rate not available")
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
                selectTokenOutPresented = true
            }
            .sheet(isPresented: $selectTokenOutPresented) {
                MultiSwapTokenSelectView(token: $viewModel.tokenOut, isPresented: $selectTokenOutPresented)
            }
        }
    }

    @ViewBuilder private func selectorButton(token: Token?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .margin8) {
                KFImage.url(token.flatMap {
                    URL(string: $0.coin.imageUrl)
                })
                .resizable()
                .placeholder {
                    Circle().fill(Color.themeSteel20)
                }
                .clipShape(Circle())
                .frame(width: .iconSize32, height: .iconSize32)

                if let token {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(token.coin.code).textSubhead1(color: .themeLeah)

                        if let protocolName = token.protocolName {
                            Text(protocolName).textMicro()
                        }
                    }
                } else {
                    Text("Select").textSubhead1(color: .themeJacob)
                }

                Image("arrow_small_down_20").themeIcon(color: .themeGray)
            }
        }
    }

    private func color(valueLevel: MultiSwapValueLevel) -> Color {
        switch valueLevel {
        case .regular: return .themeLeah
        case .warning: return .themeJacob
        case .error: return .themeLucian
        }
    }

    @ViewBuilder private func buttonView() -> some View {
        let (title, disabled, showProgress, preSwapStepId) = buttonState()

        Button(action: {
            viewModel.stopAutoQuoting()

            if let preSwapStepId {
                self.preSwapStepId = preSwapStepId
            } else {
                confirmPresented = true
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
        .buttonStyle(PrimaryButtonStyle(style: .yellow))
    }

    @ViewBuilder private func availableBalanceView(value: String) -> some View {
        ListSection {
            HStack(spacing: .margin8) {
                Text("Available Balance").textSubhead2()
                Spacer()
                Text(value)
                    .textSubhead2(color: .themeLeah)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, .margin12)
            .padding(.horizontal, .margin16)
            .frame(minHeight: 40)
        }
        .themeListStyle(.bordered)
    }

    @ViewBuilder private func quoteView(currentQuote: MultiSwapViewModel.Quote, tokenIn: Token, tokenOut: Token) -> some View {
        ListSection {
            providerView(currentQuote: currentQuote, tokenIn: tokenIn, tokenOut: tokenOut)

            VStack(spacing: 0) {
                if let price = viewModel.price {
                    priceView(value: price)
                }

                networkFeeView(currentQuote: currentQuote)

                if !currentQuote.quote.mainFields.isEmpty {
                    ForEach(currentQuote.quote.mainFields) { field in
                        providerFieldView(field: field)
                    }
                }
            }
        }
        .themeListStyle(.bordered)
        .sheet(item: $presentedSettingId) { settingId in
            if let currentQuote = viewModel.currentQuote {
                currentQuote.provider.settingView(settingId: settingId)
            }
        }
    }

    @ViewBuilder private func quoteCautionsView(currentQuote: MultiSwapViewModel.Quote) -> some View {
        if !currentQuote.quote.cautions.isEmpty {
            ForEach(currentQuote.quote.cautions.indices, id: \.self) { index in
                HighlightedTextView(caution: currentQuote.quote.cautions[index])
            }
        }
    }

    @ViewBuilder private func transactionServiceCautionsView() -> some View {
        if let transactionService = viewModel.transactionService, !transactionService.cautions.isEmpty {
            ForEach(transactionService.cautions.indices, id: \.self) { index in
                HighlightedTextView(caution: transactionService.cautions[index])
            }
        }
    }

    @ViewBuilder private func providerView(currentQuote: MultiSwapViewModel.Quote, tokenIn: Token, tokenOut: Token) -> some View {
        HStack(spacing: .margin8) {
            Button(action: {
                viewModel.stopAutoQuoting()
                quotesPresented = true
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
                settingsPresented = true
            }) {
                if currentQuote.quote.settingsModified {
                    Image("edit2_20").themeIcon(color: .themeJacob)
                } else {
                    Image("edit2_20").renderingMode(.template)
                }
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin12))
        .frame(minHeight: 40)
        .sheet(isPresented: $settingsPresented, onDismiss: { viewModel.autoQuoteIfRequired() }) {
            currentQuote.provider.settingsView(tokenIn: tokenIn, tokenOut: tokenOut) {
                viewModel.syncQuotes()
            }
        }
    }

    @ViewBuilder private func priceView(value: String) -> some View {
        HStack(spacing: .margin8) {
            Text("Price").textSubhead2()

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

    @ViewBuilder private func networkFeeView(currentQuote: MultiSwapViewModel.Quote) -> some View {
        HStack(spacing: .margin8) {
            Text("Network Fee")
                .textSubhead2()
                .modifier(Informed(description: .init(title: "Network Fee", description: "Network Fee Description")))

            Spacer()

            if let feeValue = feeValue(quote: currentQuote) {
                Text(feeValue)
                    .textSubhead2(color: .themeLeah)
                    .multilineTextAlignment(.trailing)
            } else {
                Text("n/a".localized).textSubhead2(color: .themeGray50)
            }
        }
        .padding(.vertical, .margin12)
        .padding(.trailing, .margin12)
        .frame(minHeight: 40)
    }

    @ViewBuilder private func providerFieldView(field: MultiSwapMainField) -> some View {
        HStack(spacing: .margin8) {
            if let description = field.description {
                Text(field.title)
                    .textSubhead2()
                    .modifier(Informed(description: description))
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
                    presentedSettingId = settingId
                }) {
                    if field.modified {
                        Image("edit2_20").themeIcon(color: .themeJacob)
                    } else {
                        Image("edit2_20").renderingMode(.template)
                    }
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
            }
        }
        .padding(.vertical, .margin12)
        .padding(.leading, field.description == nil ? .margin16 : 0)
        .padding(.trailing, field.settingId == nil ? .margin16 : .margin12)
        .frame(minHeight: 40)
    }

    private func feeValue(quote: MultiSwapViewModel.Quote) -> String? {
        guard let feeQuote = quote.quote.feeQuote,
              let feeToken = viewModel.feeToken,
              let transactionService = viewModel.transactionService,
              let fee = transactionService.fee(quote: feeQuote, token: feeToken),
              var result = ValueFormatter.instance.formatShort(coinValue: fee)
        else {
            return nil
        }

        if let feeTokenRate = viewModel.feeTokenRate,
           let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: fee.value * feeTokenRate)
        {
            result += " (≈ \(formatted))"
        }

        return result
    }

    private func balanceValue() -> String? {
        guard viewModel.currentQuote == nil,
              let availableBalance = viewModel.availableBalance,
              let tokenIn = viewModel.tokenIn,
              var result = ValueFormatter.instance.formatShort(coinValue: CoinValue(kind: .token(token: tokenIn), value: availableBalance))
        else {
            return nil
        }

        if let rateIn = viewModel.rateIn,
           let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: availableBalance * rateIn)
        {
            result += " (≈ \(formatted))"
        }

        return result
    }

    private func buttonState() -> (String, Bool, Bool, String?) {
        let title: String
        var disabled = true
        var showProgress = false
        var preSwapStepId: String?

        if viewModel.quoting {
            title = "Loading"
            showProgress = true
        } else if viewModel.tokenIn == nil {
            title = "Select Token In"
        } else if viewModel.tokenOut == nil {
            title = "Select Token Out"
        } else if viewModel.validProviders.isEmpty {
            title = "No Providers"
        } else if viewModel.amountIn == nil {
            title = "Enter Amount"
        } else if viewModel.currentQuote == nil {
            title = "No Quotes"
        } else if viewModel.availableBalance == nil {
            title = "Balance n/a"
        } else if let availableBalance = viewModel.availableBalance, let amountIn = viewModel.amountIn, amountIn > availableBalance {
            title = "Insufficient Balance"
        } else if let currentQuote = viewModel.currentQuote, let state = currentQuote.quote.customButtonState {
            title = state.title
            disabled = state.disabled
            showProgress = state.showProgress
            preSwapStepId = state.preSwapStepId
        } else if let currentQuote = viewModel.currentQuote, feeValue(quote: currentQuote) == nil {
            title = "Network Fee Error"
        } else {
            title = "Next"
            disabled = false
        }

        return (title, disabled, showProgress, preSwapStepId)
    }
}
