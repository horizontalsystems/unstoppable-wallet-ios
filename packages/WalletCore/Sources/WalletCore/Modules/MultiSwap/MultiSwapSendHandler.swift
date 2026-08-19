import Combine
import Foundation
import MarketKit

class MultiSwapSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .swap(tokenIn, tokenOut, amountIn, provider, multiSwapQuote, recipientHolder) = sendData else { return nil }
        return instance(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, multiSwapQuote: multiSwapQuote, recipientHolder: recipientHolder)
    }

    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let swapHistoryManager = Core.shared.swapHistoryManager
    private let mevProtectionHelper = MevProtectionHelper()

    let baseToken: Token
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let provider: IMultiSwapProvider
    // The dry-quote `MultiSwapQuote` the caller picked on the quotes screen. Passed back to
    // `provider.confirmationQuote(...)` so the provider can replay any per-quote routing state
    // (today: USwap's alternate-route selection for Exolix ZEC).
    let multiSwapQuote: MultiSwapQuote

    private var slippage = MultiSwapSlippage.default

    // Shared with the swap screen: an edit here must be visible to the pre-confirmation
    // recipient page, which pre-fills from the same box when the user returns to it.
    private let recipientHolder: SwapExternalRecipientHolder
    private var recipient: String? {
        get { recipientHolder.address }
        set { recipientHolder.address = newValue }
    }

    // tokenOut the account can't hold — the recipient was entered before confirmation,
    // is mandatory and must not be cleared (there is no own-wallet address to fall back to)
    private var recipientRequired: Bool {
        guard let accountType = accountManager.activeAccount?.type else {
            return false
        }

        return !accountType.supports(token: tokenOut)
    }

    // resolved once per confirmation: the mechanism is fixed by (chain, account)
    private lazy var broadcaster: ISwapBroadcaster? = accountManager.activeAccount.flatMap {
        try? SwapBroadcasterFactory.broadcaster(blockchainType: tokenIn.blockchainType, account: $0)
    }

    private let refreshSubject = PassthroughSubject<Void, Never>()

    init(baseToken: Token, tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, multiSwapQuote: MultiSwapQuote, recipientHolder: SwapExternalRecipientHolder) {
        self.baseToken = baseToken
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.provider = provider
        self.multiSwapQuote = multiSwapQuote
        self.recipientHolder = recipientHolder
    }
}

extension MultiSwapSendHandler: ISendHandler {
    var syncingText: String? {
        "swap.confirmation.quoting".localized
    }

    var expirationDuration: Int? {
        broadcaster?.expirationDuration ?? 15
    }

    // The swap confirm screen holds a committed provider quote (USwap's /v2/swap, and the
    // equivalent commit call on every other provider). Don't auto re-request it on expiry —
    // surface a "Refresh" button and let the user pull a fresh quote on demand.
    var autoRefreshEnabled: Bool {
        false
    }

    var menuItems: [SendMenuItem] {
        var menuItems = [SendMenuItem]()

        if provider.slippageSupported(tokenIn: tokenIn, tokenOut: tokenOut) {
            menuItems.append(
                .init(label: "swap.confirmation.slippage_tolerance".localized) { [weak self] in
                    guard let self else {
                        return
                    }

                    Coordinator.shared.present { _ in
                        MultiSwapSlippageView(slippage: self.slippage) { [weak self] slippage in
                            self?.slippage = slippage
                            self?.refreshSubject.send()
                        }
                    }
                }
            )
        }

        menuItems.append(
            .init(label: "swap.confirmation.set_recipient".localized) { [weak self] in
                guard let self else {
                    return
                }

                // Only Maya delivers ZEC to shielded/unified receivers — every other provider
                // needs a transparent recipient (CEX routes reject shielded ones at order
                // creation), matching the restriction on the pre-confirmation recipient page.
                let parserFilter: AddressParserFactory.ParserFilter? = tokenOut.blockchainType == .zcash && !(provider is MayaMultiSwapProvider) ? .zCashTransparentOnly : nil

                Coordinator.shared.present { _ in
                    MultiSwapRecipientView(address: self.recipient, token: self.tokenOut, allowRemoval: !self.recipientRequired, parserFilter: parserFilter) { [weak self] recipient in
                        guard let self else {
                            return
                        }

                        // a mandatory external recipient can be changed but never cleared
                        if recipient == nil, recipientRequired {
                            return
                        }

                        self.recipient = recipient
                        refreshSubject.send()
                    }
                }
            }
        )

        return menuItems
    }

    var refreshPublisher: AnyPublisher<Void, Never>? {
        refreshSubject.eraseToAnyPublisher()
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let quote = try await provider.confirmationQuote(
            multiSwapQuote: multiSwapQuote,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recipient: recipient,
            transactionSettings: transactionSettings
        )
        quote.preciseEstimateTime = provider.preciseEstimateTime

        guard accountManager.activeAccount != nil else {
            throw SendError.noActiveAccount
        }

        guard let broadcaster else {
            throw SwapBroadcasterError.noBroadcaster
        }

        // MEV eligibility rides on the EVM quote (set by the provider); the toggle itself
        // is read live at submit-time by the broadcaster (routing flag, not tx content)
        let otherSections = provider.mevProtectionAllowed(tokenIn: tokenIn, tokenOut: tokenOut) ? [mevProtectionHelper.section()] : []

        let executable = quote.executable(tokenIn: tokenIn)
        let prepared = try await broadcaster.prepare(executable)

        return SendData(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote, prepared: prepared, broadcaster: broadcaster, otherSections: otherSections)
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        let result: BroadcastResult
        do {
            result = try await data.broadcaster.submit(data.prepared)
        } catch {
            // Partial execution (e.g. an interactive broker session failing mid-trade after
            // txs were signed/submitted): value may already have moved on-chain. Persist a
            // trackable record with the last known hash BEFORE surfacing the error — tracking
            // then resolves the real outcome (partial fills included) instead of the swap
            // becoming an invisible ghost while the server record waits forever.
            if let partial = error as? IPartialExecutionError, let partialTxHash = partial.partialTxHash {
                saveSwap(data: data, txHash: partialTxHash, trackingHandle: nil)
            }
            throw error
        }

        saveSwap(data: data, txHash: result.txHash, trackingHandle: result.trackingHandle)

        // externally-delivered swaps must not auto-enable a wallet the account can't hold
        if !walletManager.activeWallets.contains(where: { $0.token == tokenOut }),
           let activeAccount = accountManager.activeAccount,
           activeAccount.type.supports(token: tokenOut)
        {
            let wallet = Wallet(token: tokenOut, account: activeAccount)
            walletManager.save(wallets: [wallet])
        }
    }

    /// Persist the pending swap record both completion paths need — the normal one after a
    /// successful broadcast, and the partial-execution one where the submit threw but value may
    /// already have moved (the two differ only in which hash/handle is known). No-op without an
    /// active account, matching the previous behaviour at both call sites.
    private func saveSwap(data: SendData, txHash: String?, trackingHandle: String?) {
        guard let account = accountManager.activeAccount else {
            return
        }

        let swap = Swap(
            uid: UUID().uuidString,
            txHash: txHash,
            trackingHandle: trackingHandle,
            accountId: account.id,
            providerId: provider.id,
            status: .pending,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOut: data.quote.amountOut,
            recipient: data.quote.recipient,
            toAddress: data.quote.recipient ?? data.quote.toAddress,
            depositAddress: data.quote.depositAddress,
            providerSwapId: data.quote.providerSwapId,
            sourceAddress: nil,
            refundAddress: data.quote.refundAddress,
            estimatedTime: data.quote.estimatedTime,
            date: Date(),
            fromAsset: nil,
            toAsset: nil,
            legs: nil,
            pauseReason: nil
        )

        swapHistoryManager.save(swap: swap)
    }
}

extension MultiSwapSendHandler {
    class SendData: ISendData {
        let tokenIn: Token
        let tokenOut: Token
        let amountIn: Decimal
        let quote: SwapFinalQuote
        let prepared: IPrepared
        let broadcaster: ISwapBroadcaster
        let otherSections: [SendDataSection]

        init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: SwapFinalQuote, prepared: IPrepared, broadcaster: ISwapBroadcaster, otherSections: [SendDataSection]) {
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.quote = quote
            self.prepared = prepared
            self.broadcaster = broadcaster
            self.otherSections = otherSections
        }

        var feeData: FeeData? {
            quote.feeData
        }

        var canSend: Bool {
            quote.canSwap
        }

        var rateCoins: [Coin] {
            [tokenIn.coin, tokenOut.coin]
        }

        var customSendButtonTitle: String? {
            nil
        }

        func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
            quote.cautions(baseToken: baseToken) + priceImpactCautions(baseToken: baseToken, currency: currency, rates: rates)
        }

        private func priceImpact(baseToken _: Token, currency _: Currency, rates: [String: Decimal]) -> Decimal? {
            let fiatAmountIn = rates[tokenIn.coin.uid].map { amountIn * $0 }
            let fiatAmountOut = rates[tokenOut.coin.uid].map { quote.amountOut * $0 }

            if let fiatAmountIn, let fiatAmountOut, fiatAmountIn != 0, fiatAmountIn > fiatAmountOut {
                let priceImpact = (fiatAmountOut * 100 / fiatAmountIn) - 100
                return priceImpact
            }

            return nil
        }

        private func priceImpactCautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let priceImpact = priceImpact(baseToken: baseToken, currency: currency, rates: rates) {
                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                switch level {
                case .warning: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_high".localized(PriceImpact.display(value: priceImpact)), type: .warning))
                case .forbidden: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized(PriceImpact.display(value: priceImpact)), type: .error))
                default: ()
                }
            }

            return cautions
        }

        func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            .init([
                .amount(
                    token: tokenIn,
                    appValueType: .regular(appValue: AppValue(token: tokenIn, value: amountIn)),
                    currencyValue: rates[tokenIn.coin.uid].map { CurrencyValue(currency: currency, value: amountIn * $0) },
                ),
                .amount(
                    token: tokenOut,
                    appValueType: .regular(appValue: AppValue(token: tokenOut, value: quote.amountOut)),
                    currencyValue: rates[tokenOut.coin.uid].map { CurrencyValue(currency: currency, value: quote.amountOut * $0) },
                ),
            ], isFlow: true)
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields: [SendField] = []

            fields.append(
                .price(
                    title: "swap.price".localized,
                    tokenA: tokenIn,
                    tokenB: tokenOut,
                    amountA: amountIn,
                    amountB: quote.amountOut
                )
            )

            if let priceImpact = priceImpact(baseToken: baseToken, currency: currency, rates: rates) {
                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                switch level {
                case .normal, .warning, .forbidden:
                    fields.append(
                        .simpleValue(
                            title: ComponentInformedTitle("swap.price_impact".localized, info: InfoDescription(
                                title: "swap.price_impact".localized,
                                description: "swap.price_impact.info".localized
                            )),
                            value: ComponentText(text: PriceImpact.display(value: priceImpact), colorStyle: level.valueLevel.colorStyle)
                        )
                    )
                default: ()
                }
            }

            fields.append(contentsOf: quote.fields(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                baseToken: baseToken,
                currency: currency,
                tokenInRate: rates[tokenIn.coin.uid],
                tokenOutRate: rates[tokenOut.coin.uid],
                baseTokenRate: rates[baseToken.coin.uid]
            ))

            fields.append(contentsOf: quote.feeFields(baseToken: baseToken, currency: currency, baseTokenRate: rates[baseToken.coin.uid]))

            return [
                flowSection(baseToken: baseToken, currency: currency, rates: rates),
                .init(fields, isMain: false),
            ] + otherSections
        }
    }

    enum SendError: Error {
        case invalidData
        case invalidTransactionData
        case noGasLimit
        case noGasPrice
        case noBitcoinAdapter
        case noSendParameters
        case noZcashAdapter
        case noMoneroAdapter
        case noZanoAdapter
        case noProposal
        case noActiveAccount
        case noSolanaAdapter

        case unsupportedTokenIn
        case unsupportedTokenOut
        case noCommonProvider
        case noRoutes
        case noTransactionData
        case noJettonAdapter
        case noInboundAddress
    }
}

extension MultiSwapSendHandler {
    static func instance(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, multiSwapQuote: MultiSwapQuote, recipientHolder: SwapExternalRecipientHolder) -> MultiSwapSendHandler? {
        let baseToken: Token?

        switch tokenIn.type {
        case .native, .derived, .addressType:
            baseToken = tokenIn
        case .eip20, .spl, .jetton, .stellar, .zanoAsset, .thorChainAsset:
            baseToken = try? Core.shared.marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native))
        case .unsupported:
            baseToken = nil
        }

        guard let baseToken else {
            return nil
        }

        return MultiSwapSendHandler(baseToken: baseToken, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, multiSwapQuote: multiSwapQuote, recipientHolder: recipientHolder)
    }
}
