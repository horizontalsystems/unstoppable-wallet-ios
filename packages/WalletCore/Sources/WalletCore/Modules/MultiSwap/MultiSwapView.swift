import Foundation
import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    @ObservedObject var splitViewModel: SplitSwapViewModel
    @Binding var sendPresented: Bool
    @Binding var splitRecipientsPresented: Bool
    var autoFocus = false

    @FocusState var focusedField: FocusField?
    @State var currentTab: MultiSwapTab = .standard

    private var isInputActive: Bool {
        focusedField != nil
    }

    private var activeViewModel: MultiSwapViewModel {
        currentTab == .standard ? viewModel : splitViewModel
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                FolderTabHeaderView(items: MultiSwapTab.allCases, currentItem: $currentTab) {
                    FolderTabHeaderView.Tab(title: $0.title, icon: $0.icon)
                }

                Group {
                    switch currentTab {
                    case .standard: tabView(vm: viewModel, privateSwap: false)
                    case .privateSwap: tabView(vm: splitViewModel, privateSwap: true)
                    }
                }
            }
        }
        .onChange(of: currentTab) { _, tab in
            onChange(tab: tab)
        }
        .onAppear {
            // the hidden tab's view model starts with auto quoting enabled: stop it, so provider
            // changes are deferred until the tab is shown
            switch currentTab {
            case .standard:
                splitViewModel.stopAutoQuoting()
                viewModel.autoQuoteIfRequired()
            case .privateSwap:
                viewModel.stopAutoQuoting()
                resumeSplitQuoting()
            }
        }
        .onFirstAppear {
            if autoFocus {
                focusedField = .amount
            }
        }
        .onDisappear {
            viewModel.stopAutoQuoting()
            splitViewModel.stopAutoQuoting()
        }
    }

    // Both tabs share the layout; the Private tab only adds the "Private Swap" alert card
    @ViewBuilder private func tabView(vm: MultiSwapViewModel, privateSwap: Bool) -> some View {
        BottomGradientWrapper(gradientColor: .themeLawrence) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        MultiSwapInputSection(viewModel: vm, focusedField: $focusedField, allowExternalReceive: true)

                        if let currentQuote = vm.currentQuote {
                            quoteList(quote: currentQuote, vm: vm)
                        }
                    }

                    if let path = vm.suggestedPath {
                        MultiSwapSuggestedPathView(path: path) { token in
                            vm.tokenOut = token
                        }
                        .padding(.horizontal, 16)
                    }

                    if let currentQuote = vm.currentQuote {
                        quoteCautionsView(quote: currentQuote)
                    }

                    if privateSwap {
                        AlertCardView(.init(icon: "info_filled", title: "swap.private.caution.title".localized, text: "swap.private.caution.text".localized, type: .regular))
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
            .onTapGesture {
                focusedField = nil
            }
        } bottomContent: {
            buttonView(vm: vm)
        }
        .animation(.easeOut(duration: 0.25), value: isInputActive)
    }

    private func onChange(tab: MultiSwapTab) {
        focusedField = nil

        switch tab {
        case .standard:
            splitViewModel.stopAutoQuoting()
            viewModel.autoQuoteIfRequired()
        case .privateSwap:
            viewModel.stopAutoQuoting()
            resumeSplitQuoting()
        }
    }

    // `autoQuoteIfRequired` only re-runs an interrupted or expired round: the first entry into the
    // Private tab, with no quote yet, has to start one
    private func resumeSplitQuoting() {
        splitViewModel.autoQuoteIfRequired()

        if splitViewModel.quotes.isEmpty, !splitViewModel.quoting {
            splitViewModel.syncQuotes()
        }
    }

    @ViewBuilder private func buttonView(vm: MultiSwapViewModel) -> some View {
        let (title, style, disabled, showProgress, preSwapStep) = buttonState(vm: vm)

        ThemeButton(text: title, spinner: showProgress, style: style) {
            if vm.tokenInWalletState == .notEnabled {
                focusedField = nil
                vm.enableTokenIn()
            } else {
                validatePreSwapSteps(preSwapStep, vm: vm)
            }
        }
        .disabled(disabled)
    }

    private func validatePreSwapSteps(_ preSwapStep: MultiSwapPreSwapStep?, vm: MultiSwapViewModel) {
        vm.stopAutoQuoting()

        if let preSwapStep {
            if let currentQuote = vm.currentQuote,
               let tokenIn = vm.tokenIn,
               let tokenOut = vm.tokenOut,
               let amount = vm.amountIn
            {
                Coordinator.shared.present { isPresented in
                    currentQuote.provider.preSwapView(
                        step: preSwapStep,
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        amount: amount,
                        isPresented: isPresented
                    ) {
                        vm.syncQuotes()
                    }

                } onDismiss: {
                    activeViewModel.autoQuoteIfRequired()
                }
            }
        } else {
            vm.validateAndProceed(
                onSuccess: { showSwap(vm: vm) },
                onRiskDetected: { result in showRiskBottomSheet(result, vm: vm) }
            )
        }
    }

    @ViewBuilder private func quoteList(quote: MultiSwapViewModel.Quote, vm: MultiSwapViewModel) -> some View {
        VStack(spacing: 0) {
            Cell(
                style: .secondary,
                middle: {
                    RightButtonText(text: ComponentText(text: "swap.route".localized, colorStyle: .primary), textStyle: .subhead, icon: "arrow_s_down") {
                        vm.stopAutoQuoting()

                        showSelectProvider()
                    }
                },
                right: {
                    if let price = vm.price {
                        VStack(alignment: .trailing, spacing: 3) {
                            ThemeText(price, style: .subheadSB, colorStyle: .primary)
                                .multilineTextAlignment(.trailing)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .id(price)
                                .transition(.opacity)
                                .onTapGesture {
                                    vm.flipPrice()
                                }
                        }
                        .animation(.easeInOut(duration: 0.15), value: price)
                    }
                }
            )

            Cell(
                style: .secondary,
                middle: {
                    HStack(spacing: 8) {
                        ThemeText("swap.provider.score".localized, style: .subhead, colorStyle: .secondary)
                        Image("information").icon(size: 20, colorStyle: .secondary)
                    }
                }, right: {
                    MultiSwapQuotesView.view(type: quote.provider.type)
                },
                action: {
                    onTapProviderInfo()
                }
            )

            // On the swap screen the time is shown only when it needs attention
            if let timeState = quote.timeState, case .attention = timeState {
                Cell(
                    style: .secondary,
                    middle: {
                        HStack(spacing: 8) {
                            ThemeText("swap.swapped_time".localized, style: .subhead, colorStyle: .secondary)
                            Image("information").icon(size: 20, colorStyle: .secondary)
                        }
                    }, right: {
                        MultiSwapQuotesView.view(time: timeState.value, colorStyle: timeState.colorStyle)
                    },
                    action: {
                        Coordinator.shared.present(info: .swapTime)
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder private func quoteCautionsView(quote: MultiSwapViewModel.Quote) -> some View {
        let cautions = quote.quote.cautions()

        if !cautions.isEmpty {
            ForEach(cautions.indices, id: \.self) { index in
                AlertCardView(caution: cautions[index])
            }
        }
    }

    private func showSwap(vm: MultiSwapViewModel) {
        if vm.shouldShowTerms {
            Coordinator.shared.present { isPresented in
                SwapTermsView(isPresented: isPresented) {
                    vm.onAcceptTerms()

                    DispatchQueue.main.async {
                        proceedToConfirmation(vm: vm)
                    }
                }
            } onDismiss: {
                activeViewModel.autoQuoteIfRequired()
            }
        } else {
            proceedToConfirmation(vm: vm)
        }
    }

    // tokenOut the account can't hold: ask for the external delivery address first,
    // then open the confirmation with it
    private func proceedToConfirmation(vm: MultiSwapViewModel) {
        focusedField = nil

        // the split swap's recipients are always entered on the Recipients screen
        if vm is SplitSwapViewModel {
            splitRecipientsPresented = true
            return
        }

        guard viewModel.externalRecipientRequired, let tokenOut = viewModel.tokenOut else {
            sendPresented = true
            return
        }

        Coordinator.shared.present { isPresented in
            MultiSwapExternalRecipientView(
                token: tokenOut,
                initialAddress: viewModel.externalRecipient,
                isPresented: isPresented
            ) { address in
                viewModel.setExternalRecipient(address: address)

                DispatchQueue.main.async {
                    sendPresented = true
                }
            }
        } onDismiss: {
            viewModel.autoQuoteIfRequired()
        }
    }

    private func showRiskBottomSheet(_ result: MultiSwapViewModel.AmlRiskResult, vm: MultiSwapViewModel) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: result.icon, title: result.title),
                    .subhead2(text: result.description),
                    .buttonGroup(.init(buttons: [
                        .init(style: .gray, title: result.buttonTitle) {
                            isPresented.wrappedValue = false

                            onTapResult(result, vm: vm)
                        },
                    ])),
                ]
            )
        } onDismiss: {
            activeViewModel.autoQuoteIfRequired()
        }
    }

    private func onTapResult(_ result: MultiSwapViewModel.AmlRiskResult, vm: MultiSwapViewModel) {
        switch result {
        case .dirty: showSelectProvider()
        case .unprocessed: showSwap(vm: vm)
        case .networkError:
            vm.validateAndProceed(
                onSuccess: { showSwap(vm: vm) },
                onRiskDetected: { result in showRiskBottomSheet(result, vm: vm) }
            )
        }
    }

    private func showSelectProvider() {
        DispatchQueue.main.async {
            Coordinator.shared.present { isPresented in
                MultiSwapQuotesView(viewModel: activeViewModel, isPresented: isPresented)
            } onDismiss: {
                activeViewModel.autoQuoteIfRequired()
            }
        }
    }

    private func onTapProviderInfo() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            MultiSwapProviderTypeBottomSheet(isPresented: isPresented)
        }
    }

    private func buttonState(vm: MultiSwapViewModel) -> (String, ThemeButton.Style, Bool, Bool, MultiSwapPreSwapStep?) {
        let title: String
        var style: ThemeButton.Style = .primary
        var disabled = true
        var showProgress = false
        var preSwapStep: MultiSwapPreSwapStep?

        if vm.validatingProvider {
            title = "swap.proceed_button".localized
            showProgress = true
        } else if vm.tokenInWalletState == .notEnabled, let tokenIn = vm.tokenIn {
            title = "swap.enable_coin".localized(tokenIn.coin.code)
            style = .secondary
            disabled = false
        } else if vm.tokenInWalletState == .syncing {
            title = "balance.syncing".localized
            showProgress = true
        } else if vm.quoting {
            title = "swap.quoting".localized
            showProgress = true
        } else if vm.tokenIn == nil {
            title = "swap.select_token_in".localized
        } else if vm.tokenOut == nil {
            title = "swap.select_token_out".localized
        } else if vm.validProviders.isEmpty {
            title = "swap.no_providers".localized
        } else if vm.amountIn == nil {
            title = "swap.enter_amount".localized
        } else if vm.currentQuote == nil {
            title = "swap.no_quotes".localized
        } else if vm.adapterState == nil {
            title = "swap.token_not_enabled".localized
        } else if let adapterState = vm.adapterState, !vm.spendMode.spendAllowed(state: adapterState) {
            title = "swap.token_not_synced".localized
        } else if let availableBalance = vm.availableBalance, let amountIn = vm.amountIn, amountIn > availableBalance {
            title = "swap.insufficient_balance".localized
        } else if let currentQuote = vm.currentQuote, let state = currentQuote.quote.customButtonState {
            title = state.title
            style = state.style
            disabled = state.disabled
            showProgress = state.showProgress
            preSwapStep = state.preSwapStep
        } else {
            title = vm is SplitSwapViewModel ? "send.next_button".localized : "swap.proceed_button".localized
            disabled = false
        }

        return (title, style, disabled, showProgress, preSwapStep)
    }
}

extension MultiSwapView {
    enum FocusField {
        case amount
        case fiat
    }
}

enum MultiSwapTab: CaseIterable {
    case standard
    case privateSwap

    var title: String {
        switch self {
        case .standard: return "swap.tab.standard".localized
        case .privateSwap: return "swap.tab.private".localized
        }
    }

    var icon: String? {
        switch self {
        case .privateSwap: return "fraud"
        default: return nil
        }
    }
}

struct MultiSwapSendDestinationView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    let onFinish: () -> Void

    var body: some View {
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
                multiSwapQuote: currentQuote.quote,
                recipientHolder: viewModel.externalRecipientHolder,
                onFinish: onFinish
            )
        }
    }
}
