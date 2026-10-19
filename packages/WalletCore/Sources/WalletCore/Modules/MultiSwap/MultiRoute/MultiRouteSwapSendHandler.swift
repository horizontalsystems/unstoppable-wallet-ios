import BigInt
import Combine
import EvmKit
import Foundation
import MarketKit

// A large swap divided into routes: each route is previewed, committed and sent as its own swap
// through its own provider, one transaction per route. Mirrors `MultiSwapSendHandler`.
class MultiRouteSwapSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .multiRouteSwap(tokenIn, tokenOut, routes, singleExpectedAmountOut, recipientHolder, sentRoutes) = sendData,
              !routes.isEmpty,
              let baseToken = MultiSwapSendHandler.baseToken(tokenIn: tokenIn)
        else {
            return nil
        }

        return MultiRouteSwapSendHandler(
            baseToken: baseToken,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            routes: routes,
            singleExpectedAmountOut: singleExpectedAmountOut,
            recipientHolder: recipientHolder,
            sentRoutes: sentRoutes
        )
    }

    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let adapterManager = Core.shared.adapterManager
    private let restoreSettingsManager = Core.shared.restoreSettingsManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let mevProtectionHelper = MevProtectionHelper()

    let baseToken: Token
    let tokenIn: Token
    let tokenOut: Token
    // each route has its own provider
    let routes: [MultiRouteSwapPlan.Route]
    // what the single route offered for the whole amount when the split was accepted
    let singleExpectedAmountOut: Decimal

    var amountIn: Decimal {
        routes.reduce(0) { $0 + $1.amountIn }
    }

    // applies to every route
    private var slippage = MultiSwapSlippage.default

    // Shared with the swap screen, as in `MultiSwapSendHandler`
    private let recipientHolder: SwapExternalRecipientHolder
    private var recipient: String? {
        get { recipientHolder.address }
        set { recipientHolder.address = newValue }
    }

    private var recipientRequired: Bool {
        guard let accountType = accountManager.activeAccount?.type else {
            return false
        }

        return !accountType.supports(token: tokenOut)
    }

    private lazy var broadcaster: ISwapBroadcaster? = accountManager.activeAccount.flatMap {
        try? SwapBroadcasterFactory.broadcaster(blockchainType: tokenIn.blockchainType, account: $0)
    }

    private let refreshSubject = PassthroughSubject<Void, Never>()

    // The routes already broadcast. A slide that fails after some routes went out must not send them
    // again, on the next slide or from a confirmation reopened from the same plan: they are never
    // previewed, committed or sent again. Owned by the plan, so it outlives this handler.
    private let sentRoutes: MultiRouteSentRoutesHolder

    private var sentRouteIndices: Set<Int> {
        sentRoutes.indices
    }

    init(
        baseToken: Token,
        tokenIn: Token,
        tokenOut: Token,
        routes: [MultiRouteSwapPlan.Route],
        singleExpectedAmountOut: Decimal,
        recipientHolder: SwapExternalRecipientHolder,
        sentRoutes: MultiRouteSentRoutesHolder
    ) {
        self.baseToken = baseToken
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.routes = routes
        self.singleExpectedAmountOut = singleExpectedAmountOut
        self.recipientHolder = recipientHolder
        self.sentRoutes = sentRoutes
    }

    private func balance(token: Token) -> Decimal? {
        walletManager.activeWallets
            .first { $0.token == token }
            .flatMap { adapterManager.balanceAdapter(for: $0) }?
            .balanceData.available
    }

    // The previews only check each route on its own: the account must also cover all of them together.
    // Fails closed: a balance or fee that can't be read blocks the send.
    private func balanceState(amountIn: Decimal, quotes: [SwapFinalQuote]) -> SendData.BalanceState {
        var totalFee: Decimal = 0

        for quote in quotes {
            guard let fee = quote.networkFee(feeToken: baseToken) else {
                return .unavailable
            }

            totalFee += fee
        }

        guard let balance = balance(token: baseToken) else {
            return .unavailable
        }

        let required = tokenIn == baseToken ? amountIn + totalFee : totalFee

        return required <= balance ? .sufficient : .insufficient
    }

    // Two routes may go through the same spender: each was allowed for its own part when quoted, but the
    // spender must be allowed for the parts together. Only an ERC-20 tokenIn carries an approval.
    private func allowanceSufficient(routes: [MultiRouteSwapPlan.Route], quotes: [SwapFinalQuote]) async -> Bool {
        var amountBySpender = [String: Decimal]()

        for (route, quote) in zip(routes, quotes) {
            if let spender = (quote as? EvmSwapFinalQuote)?.approval?.spender {
                amountBySpender[spender.hex, default: 0] += route.amountIn
            }
        }

        for (spender, amount) in amountBySpender {
            switch await allowanceHelper.allowanceState(spenderAddress: Address(raw: spender), token: tokenIn, amount: amount) {
            case .allowed, .notRequired: continue
            default: return false
            }
        }

        return true
    }
}

extension MultiRouteSwapSendHandler: ISendHandler {
    var syncingText: String? {
        "swap.confirmation.quoting".localized
    }

    var expirationDuration: Int? {
        broadcaster?.expirationDuration ?? 15
    }

    var autoRefreshEnabled: Bool {
        true
    }

    var menuItems: [SendMenuItem] {
        var menuItems = [SendMenuItem]()

        // one slippage for every route: offered only when every provider supports it
        if routes.allSatisfy({ $0.provider.slippageSupported(tokenIn: tokenIn, tokenOut: tokenOut) }) {
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

                // a shielded ZEC recipient only when every route's provider delivers to it
                let deliversShielded = routes.allSatisfy { Core.shared.swapProviderManager.deliversShieldedZcash(providerId: $0.provider.id) }
                let parserFilter: AddressParserFactory.ParserFilter? = tokenOut.blockchainType == .zcash && !deliversShielded ? .zCashTransparentOnly : nil

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
        guard let account = accountManager.activeAccount else {
            throw MultiSwapSendHandler.SendError.noActiveAccount
        }

        guard !account.watchAccount else {
            throw SwapBroadcasterError.noBroadcaster
        }

        guard let broadcaster else {
            throw SwapBroadcasterError.noBroadcaster
        }

        // Routes already broadcast by an earlier slide are left out: the screen shows only what is left
        let sentRouteIndices = sentRouteIndices
        let pendingRoutes = routes.enumerated()
            .filter { !sentRouteIndices.contains($0.offset) }
            .map { (index: $0.offset, route: $0.element) }

        guard !pendingRoutes.isEmpty else {
            throw MultiSwapSendHandler.SendError.noRoutes
        }

        // A nonce is never forwarded to the previews, or every route would carry the same one: the routes
        // get consecutive nonces at send time instead. The nonce setting is not offered for this send data
        // (see `EvmTransactionService.nonceLocked`), so this is a safety net.
        let userNonce = transactionSettings?.nonce
        let previewSettings: TransactionSettings? = transactionSettings.map { settings in
            if case let .evm(gasPriceData, _) = settings {
                return .evm(gasPriceData: gasPriceData, nonce: nil)
            }

            return settings
        }

        let tokenIn = tokenIn
        let tokenOut = tokenOut
        let slippage = slippage
        let recipient = recipient

        let quotes: [SwapFinalQuote] = try await withThrowingTaskGroup(of: (Int, SwapFinalQuote).self) { group in
            for (position, pending) in pendingRoutes.enumerated() {
                let route = pending.route

                group.addTask {
                    let quote = try await route.provider.confirmationQuote(
                        multiSwapQuote: route.quote,
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        amountIn: route.amountIn,
                        slippage: slippage,
                        recipient: recipient,
                        transactionSettings: previewSettings
                    )
                    quote.preciseEstimateTime = route.provider.preciseEstimateTime

                    return (position, quote)
                }
            }

            var collected = [(Int, SwapFinalQuote)]()

            for try await result in group {
                collected.append(result)
            }

            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }

        // the moment these previews are valid from; `send` refuses them once they are older than `expirationDuration`
        let previewedAt = Date()

        let pendingAmountIn = pendingRoutes.reduce(0) { $0 + $1.route.amountIn }

        // Every route must deliver to the same address, and to the one the user set, if any
        let quoteRecipients = Set(quotes.map(\.recipient))
        let recipientsMatch = quoteRecipients.count == 1 && (recipient == nil || quoteRecipients.contains(recipient))

        let allowanceSufficient = await allowanceSufficient(routes: pendingRoutes.map(\.route), quotes: quotes)

        // the single route's output for what is left to send, for the "worse than single" warning
        let totalAmountIn = amountIn
        let singleAmountOut = totalAmountIn > 0 ? singleExpectedAmountOut * pendingAmountIn / totalAmountIn : singleExpectedAmountOut

        let otherSections = quotes.allSatisfy(\.mevProtectionAllowed) ? [mevProtectionHelper.section()] : []

        return SendData(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            routes: zip(pendingRoutes, quotes).map { (index: $0.index, route: $0.route, quote: $1) },
            slippage: slippage,
            userNonce: userNonce,
            balanceState: balanceState(amountIn: pendingAmountIn, quotes: quotes),
            recipientsMatch: recipientsMatch,
            allowanceSufficient: allowanceSufficient,
            singleAmountOut: singleAmountOut,
            previewedAt: previewedAt,
            broadcaster: broadcaster,
            otherSections: otherSections
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw MultiSwapSendHandler.SendError.invalidData
        }

        // Never commit or send a route again: the data may predate a slide that already sent some
        let sentRouteIndices = sentRouteIndices
        let routes = data.routes.filter { !sentRouteIndices.contains($0.index) }

        guard !routes.isEmpty else {
            throw MultiSwapSendHandler.SendError.noRoutes
        }

        // 1. Create every order first: nothing is on-chain yet, so a failure here sends nothing.
        // The orders already created are never funded and expire server-side.
        var commitments = [SwapCommitment]()

        do {
            for item in routes {
                try Task.checkCancellation()
                let commitment = try await item.route.provider.commit(finalQuote: item.quote)
                commitments.append(commitment)
            }
        } catch {
            let message = MultiSwapSendHandler.commitFailureMessage(error)
            await MainActor.run { HudHelper.instance.show(banner: .error(string: message)) }
            refreshSubject.send()
            throw MultiSwapSendHandler.CommitFailedError(underlying: error)
        }

        // Committing several orders takes time: previews that expired meanwhile are not sent.
        // Nothing is on-chain yet; the orders just created expire unfunded.
        if let expirationDuration, Date().timeIntervalSince(data.previewedAt) > TimeInterval(expirationDuration) {
            await MainActor.run { HudHelper.instance.show(banner: .error(string: "swap.confirmation.commit.refresh_required".localized)) }
            refreshSubject.send()
            throw QuoteExpiredError()
        }

        // 2. Build and check every transaction before the first one is sent
        let executables = commitments.map { $0.quote.executable(tokenIn: tokenIn) }

        // All or nothing: a route the broadcaster would reject must be found before the first one is
        // sent, not after some routes went out. Nothing is on-chain yet; the orders expire unfunded.
        if data.broadcaster is EvmSwapBroadcaster {
            let allSendable = executables.allSatisfy { executable in
                guard let evmExecutable = executable as? EvmExecutable else {
                    return false
                }

                return evmExecutable.transactionData != nil && evmExecutable.gasLimit != nil && evmExecutable.gasPrice != nil
            }

            guard allSendable else {
                refreshSubject.send()
                throw UnsupportedRouteError()
            }
        }

        do {
            try validateNativeValues(executables: executables, routes: routes.map(\.route))
        } catch {
            refreshSubject.send()
            throw error
        }

        // 3. Send one after another with consecutive nonces, so each transaction is built
        // independently of what the node has seen of the previous ones
        do {
            var nextNonce: Int?

            for ((item, commitment), routeExecutable) in zip(zip(routes, commitments), executables) {
                var executable = routeExecutable

                // Pinning the nonce assumes the broadcaster ignores `executable.approval` (it does: the
                // allowance is settled before the swap). An approve sent by the broadcaster would need a
                // nonce of its own. `approval` is set for every ERC-20 tokenIn, even an allowed one, so it
                // can't be asserted nil here.
                if let evmExecutable = executable as? EvmExecutable, data.broadcaster is EvmSwapBroadcaster {
                    let nonce: Int

                    if let nextNonce {
                        nonce = nextNonce
                    } else {
                        nonce = try await baseNonce(userNonce: data.userNonce)
                    }

                    executable = evmExecutable.with(nonce: nonce)
                    nextNonce = nonce + 1
                }

                let prepared = try await data.broadcaster.prepare(executable)
                let result = try await data.broadcaster.submit(prepared)

                sentRoutes.markSent(index: item.index, nonce: (executable as? EvmExecutable)?.nonce)

                MultiSwapSendHandler.saveSwap(
                    provider: item.route.provider,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: item.route.amountIn,
                    commitment: commitment,
                    txHash: result.txHash,
                    trackingHandle: result.trackingHandle
                )

                // Best-effort and off the critical path, as in the single swap
                if let providerSwapId = commitment.providerSwapId, let txHash = result.txHash {
                    Task { [provider = item.route.provider] in
                        do {
                            try await provider.reportInboundTxHash(providerSwapId: providerSwapId, txHash: txHash)
                        } catch {
                            Core.instance?.logError(message: "swap signed report failed: \(error)", save: false)
                        }
                    }
                }
            }
        } catch {
            // The orders exist and the previews are consumed: re-preview so a retry never reuses them.
            // Routes already sent stay in the swap history and are left out of the re-preview.
            refreshSubject.send()
            throw error
        }

        // externally-delivered swaps must not auto-enable a wallet the account can't hold
        if !walletManager.activeWallets.contains(where: { $0.token == tokenOut }),
           let activeAccount = accountManager.activeAccount,
           activeAccount.type.supports(token: tokenOut)
        {
            restoreSettingsManager.saveDefaultSettingsIfNeeded(account: activeAccount, blockchainType: tokenOut.blockchainType)

            let wallet = Wallet(token: tokenOut, account: activeAccount)
            walletManager.save(wallets: [wallet])
        }
    }

    // A native tokenIn is paid as the transaction value: no route may spend more than its own part,
    // and the routes together no more than the parts together
    private func validateNativeValues(executables: [ISwapExecutable], routes: [MultiRouteSwapPlan.Route]) throws {
        guard tokenIn.type.isNative else {
            return
        }

        var totalValue: BigUInt = 0

        for (executable, route) in zip(executables, routes) {
            // fails closed: a transaction whose value can't be read is not sent
            guard let evmExecutable = executable as? EvmExecutable else {
                throw AmountMismatchError()
            }

            let value = evmExecutable.transactionData?.value ?? 0

            guard let maxValue = tokenIn.rawAmount(route.amountIn), value <= maxValue else {
                throw AmountMismatchError()
            }

            totalValue += value
        }

        guard let maxTotalValue = tokenIn.rawAmount(routes.reduce(0) { $0 + $1.amountIn }), totalValue <= maxTotalValue else {
            throw AmountMismatchError()
        }
    }

    // The nonce of the first route of this slide: the one set by the user, or the account's next pending nonce
    private func baseNonce(userNonce: Int?) async throws -> Int {
        let lastUsedNonce = sentRoutes.lastUsedNonce

        // Nothing sent yet: the user's nonce, if any, is still free
        if let userNonce, sentRouteIndices.isEmpty, lastUsedNonce == nil {
            return userNonce
        }

        guard let evmKit = try evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper?.evmKit else {
            throw MultiSwapSendHandler.SendError.invalidTransactionData
        }

        let pendingNonce = try await evmKit.nonce(defaultBlockParameter: .pending)

        // After a partial send the user's nonce is already taken by a route that went out. The node's
        // pending nonce can lag behind what was sent: a private (MEV-protected) send goes to a relay and
        // never reaches the public mempool, and a public one may not have propagated yet. Continuing from
        // the pending nonce alone would then reuse a nonce and replace or collide with a sent route, so
        // the remaining routes continue after the last nonce this plan used, whichever is higher.
        if let lastUsedNonce {
            return max(pendingNonce, lastUsedNonce + 1)
        }

        return pendingNonce
    }
}

extension MultiRouteSwapSendHandler {
    // The previews outlived their expiration while the orders were created; the user was told and the
    // screen re-previews, so the error is not reported again
    struct QuoteExpiredError: IHandledSendError, LocalizedError {
        var errorDescription: String? {
            "swap.confirmation.commit.refresh_required".localized
        }
    }

    // A route's transaction would spend more of a native tokenIn than its part of the swap
    struct AmountMismatchError: LocalizedError {
        var errorDescription: String? {
            "swap.multi_route.error.amount_mismatch".localized
        }
    }

    // A route's transaction is not one the broadcaster can send as is (missing data, gas limit or gas price)
    struct UnsupportedRouteError: LocalizedError {
        var errorDescription: String? {
            "swap.multi_route.error.unsupported_route".localized
        }
    }
}

extension MultiRouteSwapSendHandler {
    final class SendData: ISendData {
        enum BalanceState {
            case sufficient
            case insufficient
            case unavailable
        }

        let tokenIn: Token
        let tokenOut: Token
        // the routes still to send; `index` is the route's position in the handler's `routes`
        let routes: [(index: Int, route: MultiRouteSwapPlan.Route, quote: SwapFinalQuote)]
        let slippage: Decimal
        let userNonce: Int?
        let balanceState: BalanceState
        let recipientsMatch: Bool
        let allowanceSufficient: Bool
        // the single route's expected output for the same amount as these routes
        let singleAmountOut: Decimal
        let previewedAt: Date
        let broadcaster: ISwapBroadcaster
        let otherSections: [SendDataSection]

        init(
            tokenIn: Token,
            tokenOut: Token,
            routes: [(index: Int, route: MultiRouteSwapPlan.Route, quote: SwapFinalQuote)],
            slippage: Decimal,
            userNonce: Int?,
            balanceState: BalanceState,
            recipientsMatch: Bool,
            allowanceSufficient: Bool,
            singleAmountOut: Decimal,
            previewedAt: Date,
            broadcaster: ISwapBroadcaster,
            otherSections: [SendDataSection]
        ) {
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.routes = routes
            self.slippage = slippage
            self.userNonce = userNonce
            self.balanceState = balanceState
            self.recipientsMatch = recipientsMatch
            self.allowanceSufficient = allowanceSufficient
            self.singleAmountOut = singleAmountOut
            self.previewedAt = previewedAt
            self.broadcaster = broadcaster
            self.otherSections = otherSections
        }

        private var quotes: [SwapFinalQuote] {
            routes.map(\.quote)
        }

        private var amountIn: Decimal {
            routes.reduce(0) { $0 + $1.route.amountIn }
        }

        private var amountOut: Decimal {
            quotes.reduce(0) { $0 + $1.amountOut }
        }

        // nil unless every route has one
        private var guaranteedAmountOut: Decimal? {
            var total: Decimal = 0

            for quote in quotes {
                guard let value = quote.guaranteedAmountOut else {
                    return nil
                }

                total += value
            }

            return total
        }

        private func networkFee(feeToken: Token) -> Decimal? {
            var total: Decimal = 0

            for quote in quotes {
                guard let fee = quote.networkFee(feeToken: feeToken) else {
                    return nil
                }

                total += fee
            }

            return total
        }

        private func priceImpact(rates: [String: Decimal]) -> Decimal? {
            MultiSwapSendHandler.priceImpact(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, amountOut: amountOut, rates: rates)
        }

        // the first route's fee data keeps the gas price settings working; the price chosen applies to every route
        var feeData: FeeData? {
            quotes.first?.feeData
        }

        var canSend: Bool {
            quotes.allSatisfy(\.canSwap) && balanceState == .sufficient && recipientsMatch && allowanceSufficient
        }

        var rateCoins: [Coin] {
            [tokenIn.coin, tokenOut.coin]
        }

        var customSendButtonTitle: String? {
            nil
        }

        func cautions(baseToken: Token, currency _: Currency, rates: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            // the same problem on several routes is shown once
            for caution in quotes.flatMap({ $0.cautions(baseToken: baseToken) }) where !cautions.contains(where: { ($0.title ?? $0.text) == (caution.title ?? caution.text) }) {
                cautions.append(caution)
            }

            switch balanceState {
            case .sufficient: ()
            case .insufficient:
                cautions.append(
                    CautionNew(
                        title: "fee_settings.errors.insufficient_balance".localized,
                        text: "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseToken.coinCodeWithBadge),
                        type: .error
                    )
                )
            case .unavailable:
                // a route that can't be sent already explains why
                if quotes.allSatisfy(\.canSwap) {
                    cautions.append(CautionNew(text: "swap.multi_route.balance_unavailable".localized, type: .error))
                }
            }

            if !recipientsMatch {
                cautions.append(CautionNew(text: "swap.multi_route.recipient_mismatch".localized, type: .error))
            }

            if !allowanceSufficient {
                cautions.append(CautionNew(title: "swap.allowance_error".localized, text: "swap.multi_route.allowance_not_enough".localized, type: .error))
            }

            if amountOut < singleAmountOut {
                cautions.append(CautionNew(text: "swap.multi_route.worse_than_single".localized, type: .warning))
            }

            return cautions + MultiSwapSendHandler.priceImpactCautions(priceImpact: priceImpact(rates: rates))
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = MultiSwapSendHandler.priceFields(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                priceImpact: priceImpact(rates: rates)
            )

            if let guaranteedAmountOut, let minRecieve = SendField.minRecieve(token: tokenOut, value: guaranteedAmountOut) {
                fields.append(minRecieve)
            }

            if let slippage = SendField.slippage(slippage) {
                fields.append(slippage)
            }

            if let recipient = quotes.first?.recipient {
                fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
            }

            fields.append(
                .simpleValue(
                    title: ComponentInformedTitle(
                        "swap.confirmation.split_across".localized,
                        info: InfoDescription(title: "swap.confirmation.split_across".localized, description: "swap.confirmation.split_across.info".localized)
                    ),
                    value: ComponentText(text: "swap.confirmation.split_across.value".localized(routes.count), colorStyle: .primary)
                )
            )

            // the longest route
            let longestTime = quotes.compactMap(\.estimatedTime).max()

            if let swapTimeField = SwapFinalQuote.swapTimeField(estimatedTime: longestTime, precise: quotes.allSatisfy(\.preciseEstimateTime)) {
                fields.append(swapTimeField)
            }

            let feeAmountData = networkFee(feeToken: baseToken).map { fee in
                AmountData(
                    appValue: AppValue(token: baseToken, value: fee),
                    currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) }
                )
            }

            fields.append(
                .fee(
                    title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                    amountData: feeAmountData
                )
            )

            return [
                MultiSwapSendHandler.flowSection(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, amountOut: amountOut, currency: currency, rates: rates),
                .init(fields, isMain: false),
            ] + otherSections
        }
    }
}
