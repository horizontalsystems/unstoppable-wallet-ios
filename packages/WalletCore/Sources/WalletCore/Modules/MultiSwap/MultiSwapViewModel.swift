import Combine
import Foundation
import HsExtensions
import MarketKit
import RxSwift

public class MultiSwapViewModel: ObservableObject {
    private let autoRefreshDuration: Double = 20

    private var cancellables = Set<AnyCancellable>()
    private var disposeBag = DisposeBag()
    private var providerCancellables = Set<AnyCancellable>()
    private var quotesTask: AnyTask?
    private var swapTask: AnyTask?
    private var defaultTokensTask: AnyTask?
    private var rateInCancellable: AnyCancellable?
    private var rateOutCancellable: AnyCancellable?
    private var timer: Timer?

    private var balanceDisposeBag = DisposeBag()

    private var providers: [IMultiSwapProvider]
    private let swapProviderManager = Core.shared.swapProviderManager
    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let adapterManager = Core.shared.adapterManager
    private let localStorage = Core.shared.localStorage

    @Published var currency: Currency
    private let customDecimals: Int?

    private let hasExplicitToken: Bool
    private let autoResolveTokenOut: Bool
    private var tokensManuallySet = false
    private var currentAccountId: String?
    private var defaultTokensCancellable: AnyCancellable?

    private var enteringFiat = false

    // External delivery address entered before confirmation for a tokenOut the account
    // can't hold. Shared with the confirmation handler, which writes back into it when the
    // user edits the recipient there. Cleared whenever tokenOut changes or the account
    // switches, so it can only ever hold an address meant for the current pair.
    let externalRecipientHolder = SwapExternalRecipientHolder()

    var externalRecipient: String? {
        // Only honored while the address is actually required: a recipient set on the
        // confirmation screen of an ordinary swap stays local to that confirmation, as before.
        externalRecipientRequired ? externalRecipientHolder.address : nil
    }

    func setExternalRecipient(address: String) {
        externalRecipientHolder.address = address
    }

    // tokenOut the account can't hold: the swap is deliverable only to an external
    // address, which the user is asked for before the confirmation screen
    var externalRecipientRequired: Bool {
        externalRecipientRequired(tokenOut: internalTokenOut)
    }

    private func externalRecipientRequired(tokenOut: Token?) -> Bool {
        guard let tokenOut, let accountType = accountManager.activeAccount?.type else {
            return false
        }

        return !accountType.supports(token: tokenOut)
    }

    @Published public var validProviders = [IMultiSwapProvider]()

    private var internalTokenIn: Token? {
        didSet {
            guard internalTokenIn != oldValue else {
                return
            }

            syncValidProviders()

            if internalTokenIn != tokenIn {
                tokenIn = internalTokenIn
            }

            if let internalTokenIn {
                coinPriceIn = marketKit.coinPrice(coinUid: internalTokenIn.coin.uid, currencyCode: currency.code)
                rateInCancellable = marketKit.coinPricePublisher(coinUid: internalTokenIn.coin.uid, currencyCode: currency.code)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] price in self?.coinPriceIn = price }
            } else {
                coinPriceIn = nil
                rateInCancellable = nil
            }

            syncAdapter()
        }
    }

    @Published public var tokenIn: Token? {
        didSet {
            guard internalTokenIn != tokenIn else {
                return
            }

            tokensManuallySet = true

            if enteringFiat {
                fiatAmountIn = nil
            } else {
                amountIn = nil
            }

            let oldTokenIn = internalTokenIn

            internalTokenIn = tokenIn

            if internalTokenOut == tokenIn {
                internalTokenOut = oldTokenIn
            }

            priceFlipped = false
            internalUserSelectedProviderId = nil

            syncQuotes()
        }
    }

    private var internalTokenOut: Token? {
        didSet {
            guard internalTokenOut != oldValue else {
                return
            }

            // An address entered for the previous tokenOut is meaningless for the new one —
            // and would otherwise be picked up as the confirmation's initial recipient.
            externalRecipientHolder.address = nil

            syncValidProviders()

            if internalTokenOut != tokenOut {
                tokenOut = internalTokenOut
            }

            if let internalTokenOut {
                rateOut = marketKit.coinPrice(coinUid: internalTokenOut.coin.uid, currencyCode: currency.code)?.value
                rateOutCancellable = marketKit.coinPricePublisher(coinUid: internalTokenOut.coin.uid, currencyCode: currency.code)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] price in self?.rateOut = price.value }
            } else {
                rateOut = nil
                rateOutCancellable = nil
            }
        }
    }

    @Published public var tokenOut: Token? {
        didSet {
            guard internalTokenOut != tokenOut else {
                return
            }

            // picking the current sell token on the You Get side swaps the pair — blocked
            // when the current tokenOut needs external delivery (same rule as the switch
            // arrow), else an externally-delivered token would become the unsignable sell side
            if internalTokenIn == tokenOut, externalRecipientRequired(tokenOut: internalTokenOut) {
                tokenOut = internalTokenOut
                return
            }

            tokensManuallySet = true

            let oldTokenOut = internalTokenOut

            internalTokenOut = tokenOut

            if internalTokenIn == tokenOut {
                amountIn = nil
                internalTokenIn = oldTokenOut
            }

            priceFlipped = false
            internalUserSelectedProviderId = nil

            syncQuotes()
        }
    }

    @Published public var adapterState: AdapterState?
    @Published public var availableBalance: Decimal?

    var spendMode: BalanceAdapterSpendMode

    @Published var coinPriceIn: CoinPrice? {
        didSet {
            syncFiatAmountIn()
        }
    }

    @Published var rateOut: Decimal? {
        didSet {
            syncFiatAmountOut()
        }
    }

    public var amountIn: Decimal? {
        didSet {
            internalUserSelectedProviderId = nil

            syncQuotes()
            syncFiatAmountIn()

            let amount = AmountDecimalParser.parseAnyDecimal(from: amountString)

            if amount != amountIn {
                amountString = AmountDecimalParser.string(from: amountIn)
            }
        }
    }

    @Published public var amountString: String = "" {
        didSet {
            let amount = AmountDecimalParser.parseAnyDecimal(from: amountString)

            guard amount != amountIn else {
                return
            }

            enteringFiat = false

            amountIn = amount
        }
    }

    @Published var fiatAmountIn: Decimal? {
        didSet {
            syncAmountIn()

            let amount = AmountDecimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

            if amount != fiatAmountIn {
                fiatAmountString = AmountDecimalParser.string(from: fiatAmountIn)
            }
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let amount = AmountDecimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

            guard amount != fiatAmountIn else {
                return
            }

            enteringFiat = true

            fiatAmountIn = amount
        }
    }

    @Published public var currentQuote: Quote? {
        didSet {
            amountOut = currentQuote?.quote.expectedBuyAmount
            syncFiatAmountOut()
            syncPrice()
        }
    }

    @Published var bestQuote: Quote?

    private var internalUserSelectedProviderId: String? {
        didSet {
            guard internalUserSelectedProviderId != oldValue else {
                return
            }

            if internalUserSelectedProviderId != userSelectedProviderId {
                userSelectedProviderId = internalUserSelectedProviderId
            }
        }
    }

    @Published public var userSelectedProviderId: String? {
        didSet {
            guard userSelectedProviderId != internalUserSelectedProviderId else {
                return
            }

            internalUserSelectedProviderId = userSelectedProviderId
            syncCurrentQuote()
        }
    }

    @Published var quotes: [Quote] = [] {
        didSet {
            bestQuote = quotes.max { $0.quote.expectedBuyAmount < $1.quote.expectedBuyAmount }

            syncCurrentQuote()

            timer?.invalidate()
            nextQuoteTime = nil

            if !quotes.isEmpty {
                nextQuoteTime = Date().timeIntervalSince1970 + autoRefreshDuration

                timer = Timer.scheduledTimer(withTimeInterval: autoRefreshDuration, repeats: false) { [weak self] _ in
                    self?.syncQuotes(silent: true)
                }
            }
        }
    }

    @Published public var amountOut: Decimal?
    @Published var fiatAmountOut: Decimal? {
        didSet {
            syncPriceImpact()
        }
    }

    @Published var price: String?
    private var priceFlipped = false

    @Published public var quoting = false
    @Published public var validatingProvider = false
    private var nextQuoteTime: Double?

    @Published var priceImpact: Decimal?

    @Published var quoteSortType: QuoteSortType = .bestRate

    public init(token: Token? = nil, tokenOut: Token? = nil, autoResolveTokenOut: Bool = true, customDecimals: Int? = nil) {
        providers = SwapProviderFactory.swappableProviders(ids: swapProviderManager.providers)
        currency = currencyManager.baseCurrency
        spendMode = .fromBalanceState
        self.customDecimals = customDecimals
        hasExplicitToken = token != nil || tokenOut != nil
        self.autoResolveTokenOut = autoResolveTokenOut
        currentAccountId = accountManager.activeAccount?.id

        defer {
            if token != nil || tokenOut != nil {
                internalTokenIn = token
                internalTokenOut = tokenOut
                syncDefaultTokens()
            } else {
                scheduleDefaultTokensSync()
            }
        }

        currencyManager.$baseCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currency = $0 }
            .store(in: &cancellables)

        // Fires on EVERY successful sync, not only when the id list actually changes —
        // `@PostPublished` is a plain PassthroughSubject with no equality check (that is the
        // separate `DistinctPublished`). That is what lets this one subscription cover suspensions
        // too: the manager assigns them just before `providers`, so a sync that only changes which
        // PAIRS a provider may serve still refreshes here. A second subscription on `$suspensions`
        // would fire from the same response and cancel this refresh mid-flight, wasting a full
        // round of provider requests.
        swapProviderManager.$providers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.providers = SwapProviderFactory.swappableProviders(ids: $0)
                self?.syncValidProviders()
                self?.syncQuotes(silent: true)
                self?.subscribeToProviders()
            }
            .store(in: &cancellables)

        walletManager.activeWalletDataUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletData in
                self?.handle(walletData: walletData)
            }
            .store(in: &cancellables)

        adapterManager.adapterDataReadyPublisher
            // off the sender's serial queue: syncAdapter re-enters adapterManager.queue.sync
            // (the Rx subscribe helper hopped via observeOn(Concurrent...) — keep that semantic)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in
                self?.syncAdapter()
            }
            .store(in: &cancellables)

        subscribeToProviders()

        syncFiatAmountIn()
        syncFiatAmountOut()

        swapProviderManager.sync()
    }

    // account switched -> full re-resolve; enabled source disappeared (spec rule 1.3) -> re-resolve
    private func handle(walletData: WalletManager.WalletData) {
        let accountChanged = walletData.account?.id != currentAccountId
        currentAccountId = walletData.account?.id

        if accountChanged {
            // an external recipient entered for the previous account must not silently
            // redirect the new account's swaps, even if the pair stays the same — also
            // with an explicit token, where no default-pair re-resolve happens below
            externalRecipientHolder.address = nil
        }

        guard !hasExplicitToken else {
            return
        }

        if accountChanged {
            tokensManuallySet = false
            scheduleDefaultTokensSync()
            return
        }

        if !tokensManuallySet, let internalTokenIn, !walletData.wallets.contains(where: { $0.token == internalTokenIn }) {
            scheduleDefaultTokensSync()
        }
    }

    // one-shot: resolve now if adapters are ready or there is nothing to wait for, otherwise once on ready
    private func scheduleDefaultTokensSync() {
        defaultTokensCancellable = nil

        let wallets = walletManager.activeWallets
        let resolvesImmediately = wallets.isEmpty || wallets.contains { adapterManager.balanceAdapter(for: $0) != nil }

        if resolvesImmediately {
            syncDefaultTokens()
            return
        }

        defaultTokensCancellable = adapterManager.adapterDataReadyPublisher
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncDefaultTokens()
            }
    }

    private func syncDefaultTokens() {
        guard !tokensManuallySet else {
            return
        }

        if hasExplicitToken {
            guard autoResolveTokenOut, internalTokenIn == nil || internalTokenOut == nil else {
                return
            }
        }

        let explicitToken = hasExplicitToken ? internalTokenIn : nil
        let explicitTokenOut = hasExplicitToken ? internalTokenOut : nil
        let currencyCode = currency.code

        defaultTokensTask = Task { [weak self] in
            guard let self else {
                return
            }

            let bitcoin = try? marketKit.token(query: BlockchainType.bitcoin.defaultTokenQuery)
            let monero = try? marketKit.token(query: BlockchainType.monero.defaultTokenQuery)

            let wallets = walletManager.activeWallets
            let coinPriceMap = marketKit.coinPriceMap(coinUids: wallets.map(\.coin.uid).removeDuplicates(), currencyCode: currencyCode)

            let items = wallets.map { wallet in
                MultiSwapDefaultPairResolver.Item(
                    token: wallet.token,
                    balance: adapterManager.balanceAdapter(for: wallet)?.balanceData.available ?? 0,
                    price: coinPriceMap[wallet.coin.uid]?.value
                )
            }

            let pair = MultiSwapDefaultPairResolver.resolve(
                .init(
                    explicitToken: explicitToken,
                    explicitTokenOut: explicitTokenOut,
                    autoResolveTokenOut: autoResolveTokenOut,
                    hasWallets: accountManager.activeAccount != nil && !wallets.isEmpty,
                    items: items,
                    popularTokens: { [marketKit] in MultiSwapPopularTokenResolver.tokens(marketKit: marketKit, for: $0) },
                    bitcoin: bitcoin,
                    monero: monero
                )
            )

            guard !Task.isCancelled else {
                return
            }

            await apply(tokenIn: pair.tokenIn, tokenOut: pair.tokenOut)
        }
        .erased()
    }

    @MainActor private func apply(tokenIn: Token?, tokenOut: Token?) {
        guard !tokensManuallySet else {
            return
        }

        if hasExplicitToken {
            if internalTokenOut == nil, let tokenOut {
                internalTokenOut = activeWalletToken(for: tokenOut)
            }

            if internalTokenIn == nil, let tokenIn {
                internalTokenIn = activeWalletToken(for: tokenIn)
            }

            return
        }

        set(
            tokenIn: tokenIn.map { activeWalletToken(for: $0) },
            tokenOut: tokenOut.map { activeWalletToken(for: $0) }
        )
    }

    private func set(tokenIn: Token?, tokenOut: Token?) {
        guard tokenIn != internalTokenIn || tokenOut != internalTokenOut else {
            return
        }

        internalTokenIn = tokenIn
        internalTokenOut = tokenOut

        priceFlipped = false
        internalUserSelectedProviderId = nil

        if enteringFiat {
            fiatAmountIn = nil
        } else {
            amountIn = nil
        }
    }

    private func activeWalletToken(for token: Token) -> Token {
        walletManager.activeWallets.first { $0.token.coin.uid == token.coin.uid && $0.token.blockchainType == token.blockchainType }?.token ?? token
    }

    private func syncAdapter() {
        balanceDisposeBag = .init()

        if let internalTokenIn,
           let wallet = walletManager.activeWallets.first(where: { $0.token == internalTokenIn }),
           let adapter = adapterManager.balanceAdapter(for: wallet)
        {
            let balanceState = adapter.balanceState
            let balance = adapter.balanceData.available
            let mode = adapter.spendMode

            DispatchQueue.main.async { [weak self] in
                self?.adapterState = balanceState
                self?.availableBalance = balance
                self?.spendMode = mode
            }

            adapter.balanceStateUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self, weak adapter] state in
                    self?.adapterState = state
                    self?.spendMode = adapter?.spendMode ?? .fromBalanceState
                }
                .disposed(by: balanceDisposeBag)

            adapter.balanceDataUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] balanceData in
                    self?.availableBalance = balanceData.available
                }
                .disposed(by: balanceDisposeBag)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.adapterState = nil
                self?.availableBalance = nil
                self?.spendMode = .fromBalanceState
            }
        }
    }

    func subscribeToProviders() {
        providerCancellables = Set<AnyCancellable>()

        for provider in providers {
            if let syncPublisher = provider.syncPublisher {
                syncPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        self?.syncValidProviders()
                        self?.syncQuotes(silent: true)
                    }
                    .store(in: &providerCancellables)
            }
        }
    }

    private func syncValidProviders() {
        if let internalTokenIn, let internalTokenOut {
            let suspensions = swapProviderManager.suspensions

            validProviders = providers.filter { provider in
                // Scoped suspension from uswap-server (asset / chain / directed pair). Checked
                // HERE, in the one place every provider passes through, rather than inside each
                // `supports` implementation — and it is the only enforcement that exists for the
                // providers this app quotes natively, since those never reach the server.
                guard !suspensions.isSuspended(providerId: provider.id, tokenIn: internalTokenIn, tokenOut: internalTokenOut) else {
                    return false
                }

                return provider.supports(tokenIn: internalTokenIn, tokenOut: internalTokenOut)
            }
        } else {
            validProviders = []
        }
    }

    private func syncCurrentQuote() {
        if let internalUserSelectedProviderId {
            currentQuote = quotes.first { $0.provider.id == internalUserSelectedProviderId } ?? bestQuote
        } else {
            currentQuote = bestQuote
        }
    }

    private func syncAmountIn() {
        guard enteringFiat else {
            return
        }

        guard let coinPriceIn, let fiatAmountIn, let tokenIn else {
            amountIn = nil
            return
        }

        amountIn = (fiatAmountIn / coinPriceIn.value).roundedDown(decimal: customDecimals ?? tokenIn.decimals)
    }

    private func syncFiatAmountIn() {
        guard !enteringFiat else {
            return
        }

        guard let coinPriceIn, let amountIn else {
            fiatAmountIn = nil
            return
        }

        fiatAmountIn = (amountIn * coinPriceIn.value).rounded(decimal: 2)
    }

    private func syncFiatAmountOut() {
        guard let rateOut, let currentQuote else {
            fiatAmountOut = nil
            return
        }

        fiatAmountOut = (currentQuote.quote.expectedBuyAmount * rateOut).rounded(decimal: 2)
    }

    func syncPriceImpact() {
        guard let fiatAmountIn, let fiatAmountOut, fiatAmountIn != 0, fiatAmountIn > fiatAmountOut else {
            priceImpact = nil
            return
        }

        priceImpact = (fiatAmountOut * 100 / fiatAmountIn) - 100
    }

    func syncQuotes(silent: Bool = false) {
        quotesTask = nil

        if !silent {
            quotes = []
        }

        guard let internalTokenIn, let internalTokenOut, let amountIn, amountIn != 0 else {
            if quoting {
                quoting = false
            }

            return
        }

        guard !validProviders.isEmpty else {
            if quoting {
                quoting = false
            }

            return
        }

        if !quoting, !silent {
            quoting = true
        }

        quotesTask = Task { [weak self, validProviders] in
            let optionalQuotes: [Quote?] = await withTaskGroup(of: Quote?.self) { group in
                for provider in validProviders {
                    group.addTask {
                        do {
                            let quoteTask = Task {
                                try await provider.quote(tokenIn: internalTokenIn, tokenOut: internalTokenOut, amountIn: amountIn)
                            }

                            // Per-provider quote timeout. Must exceed uswap-server's own budget
                            // (12s per provider / 15s overall) or slow-but-valid cross-chain
                            // aggregators — LI.FI, Jupiter — get cancelled mid-quote and surface as
                            // `explicitlyCancelled` (e.g. an ETH→Tron TRC-20 route that legitimately
                            // takes several seconds). 5s was cutting those off.
                            let timeoutTask = Task {
                                try await Task.sleep(seconds: 15)
                                quoteTask.cancel()
                            }

                            return try await withTaskCancellationHandler {
                                let quote = try await quoteTask.value
                                timeoutTask.cancel()

                                return Quote(provider: provider, quote: quote)
                            } onCancel: {
                                quoteTask.cancel()
                                timeoutTask.cancel()
                            }
                        } catch {
                            print("QUOTE ERROR: \(provider.id): \(error)")
                            return nil
                        }
                    }
                }

                var quotes = [Quote?]()

                for await quote in group {
                    quotes.append(quote)
                }

                return quotes
            }

            let quotes = optionalQuotes.compactMap { $0 }.sorted { $0.quote.expectedBuyAmount > $1.quote.expectedBuyAmount }
            let decorated = Self.decorated(quotes: quotes)

            if !Task.isCancelled {
                await MainActor.run { [weak self, decorated] in
                    self?.quoting = false
                    self?.quotes = decorated
                }
            }
        }
        .erased()
    }

    private func syncPrice() {
        if let tokenIn, let tokenOut, let amountIn, amountIn != 0, let amountOut = currentQuote?.quote.expectedBuyAmount {
            var showAsIn = amountIn < amountOut

            if priceFlipped {
                showAsIn.toggle()
            }

            let tokenA = showAsIn ? tokenIn : tokenOut
            let tokenB = showAsIn ? tokenOut : tokenIn
            let amountA = showAsIn ? amountIn : amountOut
            let amountB = showAsIn ? amountOut : amountIn

            let formattedValue = ValueFormatter.instance.formatFull(value: amountB / amountA, decimalCount: tokenB.decimals)
            price = formattedValue.map { "1 \(tokenA.coin.code) = \($0) \(tokenB.coin.code)" }
        } else {
            price = nil
        }
    }
}

public extension MultiSwapViewModel {
    internal var shouldShowTerms: Bool {
        guard let currentQuote else {
            return false
        }

        return currentQuote.provider.requireTerms && !localStorage.swapTermsAccepted
    }

    internal func onAcceptTerms() {
        localStorage.swapTermsAccepted = true
    }

    func interchange() {
        // an externally-delivered tokenOut can't become the sell side — the account
        // can't sign transactions for it
        guard !externalRecipientRequired else {
            return
        }

        tokensManuallySet = true

        let currentFiatAmountOut = fiatAmountOut
        let currentAmountOut = currentQuote?.quote.expectedBuyAmount

        let internalTokenIn = internalTokenIn
        self.internalTokenIn = internalTokenOut
        internalTokenOut = internalTokenIn

        if enteringFiat {
            fiatAmountIn = currentFiatAmountOut
        } else {
            amountIn = currentAmountOut
        }
    }

    internal func flipPrice() {
        priceFlipped.toggle()
        syncPrice()
    }

    func setAmountIn(percent: Int) {
        guard let tokenIn, let availableBalance else {
            return
        }

        enteringFiat = false

        amountIn = (availableBalance * Decimal(percent) / 100).roundedDown(decimal: customDecimals ?? tokenIn.decimals)
    }

    func clearAmountIn() {
        enteringFiat = false
        amountIn = nil
    }

    func stopAutoQuoting() {
        timer?.invalidate()
    }

    func autoQuoteIfRequired() {
        guard !quoting, let nextQuoteTime else {
            return
        }

        let now = Date().timeIntervalSince1970

        if now > nextQuoteTime {
            syncQuotes(silent: true)
        } else {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: nextQuoteTime - now, repeats: false) { [weak self] _ in
                self?.syncQuotes(silent: true)
            }
        }
    }

    func reset() {
        amountIn = nil
    }

    internal func validateAndProceed(onSuccess: @escaping () -> Void, onRiskDetected: @escaping (AmlRiskResult) -> Void) {
        guard let currentQuote, let tokenIn = internalTokenIn else {
            return
        }

        if let debuggingResult = localStorage.debuggingAmlCheckResult {
            onRiskDetected(debuggingResult)
            return
        }

        validatingProvider = true
        let amountIn = amountIn ?? 0

        Task { [weak self, provider = currentQuote.provider] in
            let hasNetworkError: Bool
            let trusted: Bool?

            do {
                trusted = try await provider.validateTrustedProvider(tokenIn: tokenIn, amountIn: amountIn)
                hasNetworkError = false
            } catch {
                trusted = nil
                hasNetworkError = true
            }

            guard let self else { return }

            await MainActor.run {
                self.validatingProvider = false

                guard !hasNetworkError else {
                    onRiskDetected(.networkError)
                    return
                }

                guard let trusted else {
                    onRiskDetected(.unprocessed)
                    return
                }

                if trusted {
                    onSuccess()
                } else {
                    onRiskDetected(.dirty)
                }
            }
        }
    }

    var sortedQuotes: [Quote] {
        switch quoteSortType {
        case .bestRate:
            return quotes.sorted { $0.quote.expectedBuyAmount > $1.quote.expectedBuyAmount }
        case .bestTime:
            return quotes.sorted {
                let t0 = $0.quote.estimatedTime ?? .infinity
                let t1 = $1.quote.estimatedTime ?? .infinity
                if t0 != t1 { return t0 < t1 }
                return $0.quote.expectedBuyAmount > $1.quote.expectedBuyAmount
            }
        }
    }
}

extension MultiSwapViewModel {
    public struct Quote {
        public let provider: IMultiSwapProvider
        public let quote: MultiSwapQuote
        let timeState: SwapTimeState?
    }

    enum SwapTimeValue: Equatable {
        case approximate(TimeInterval)
        case range(min: TimeInterval, max: TimeInterval)
    }

    enum SwapTimeState: Equatable {
        case neutral(SwapTimeValue)
        case attention(SwapTimeValue)

        var value: SwapTimeValue {
            switch self {
            case let .neutral(value), let .attention(value): return value
            }
        }

        var colorStyle: ColorStyle {
            switch self {
            case .neutral: return .secondary
            case .attention: return .yellow
            }
        }
    }

    enum QuoteSortType: CaseIterable {
        case bestRate
        case bestTime

        var title: String {
            switch self {
            case .bestRate: return "swap.quotes.sort.best_rate".localized
            case .bestTime: return "swap.quotes.sort.best_time".localized
            }
        }
    }

    enum PriceImpactLevel {
        case negligible
        case low
        case normal
        case warning
        case forbidden

        private static let lowPriceImpact: Decimal = 1
        private static let normalPriceImpact: Decimal = 5
        private static let warningPriceImpact: Decimal = 10
        private static let forbiddenPriceImpact: Decimal = 50

        init(priceImpact: Decimal) {
            switch priceImpact {
            case 0 ..< Self.lowPriceImpact: self = .negligible
            case Self.lowPriceImpact ..< Self.normalPriceImpact: self = .low
            case Self.normalPriceImpact ..< Self.warningPriceImpact: self = .normal
            case Self.warningPriceImpact ..< Self.forbiddenPriceImpact: self = .warning
            default: self = .forbidden
            }
        }

        var valueLevel: ValueLevel {
            switch self {
            case .negligible, .low: return .regular
            case .normal: return .warning
            case .warning, .forbidden: return .error
            }
        }
    }

    enum AmlRiskResult: String, CaseIterable {
        case dirty
        case unprocessed
        case networkError

        var title: String {
            switch self {
            case .dirty, .unprocessed: return "swap.aml.risk.title".localized
            case .networkError: return "swap.aml.connection.title".localized
            }
        }

        var description: String {
            switch self {
            case .dirty: return "swap.aml.risk.description".localized
            case .unprocessed: return "swap.aml.undefined.description".localized
            case .networkError: return "swap.aml.connection.description".localized
            }
        }

        var buttonTitle: String {
            switch self {
            case .dirty: return "swap.aml.risk.button".localized
            case .unprocessed: return "swap.aml.undefined.button".localized
            case .networkError: return "swap.aml.connection.button".localized
            }
        }

        var icon: ComponentImage {
            switch self {
            case .dirty, .networkError: return ThemeImage.error
            case .unprocessed: return ThemeImage.warning
            }
        }
    }
}

enum PriceImpact {
    static func display(value: Decimal) -> String {
        "-\(abs(value).rounded(decimal: 2).description)%"
    }
}

extension MultiSwapViewModel.Quote {
    init(provider: IMultiSwapProvider, quote: MultiSwapQuote) {
        self.init(provider: provider, quote: quote, timeState: nil)
    }
}

extension MultiSwapViewModel {
    private static let timeWarningThreshold: TimeInterval = 30 * 60
    private static let timeWarningRatio: Double = 2

    private static func decorated(quotes: [Quote]) -> [Quote] {
        let times = quotes.compactMap { quote -> TimeInterval? in
            guard let time = quote.quote.estimatedTime, time > 0 else { return nil }
            return time
        }
        let baseline: TimeInterval? = times.count >= 2 ? times.min() : nil

        return quotes.map { item in
            Quote(
                provider: item.provider,
                quote: item.quote,
                timeState: timeState(for: item.quote.estimatedTime, precise: item.provider.preciseEstimateTime, baseline: baseline)
            )
        }
    }

    // internal visibility intentional: pure function covered by unit tests via @testable import.
    static func timeState(for time: TimeInterval?, precise: Bool, baseline: TimeInterval?) -> SwapTimeState? {
        guard let time, time > 0 else { return nil }
        // An imprecise estimate renders as (X−25%)–(X+25%); the warning rule judges its upper bound.
        let value: SwapTimeValue = precise ? .approximate(time) : .range(min: time * 0.75, max: time * 1.25)
        let comparisonTime = precise ? time : time * 1.25
        if warningTime(for: comparisonTime, baseline: baseline) != nil {
            return .attention(value)
        }
        return .neutral(value)
    }

    // internal visibility intentional: pure function covered by unit tests via @testable import.
    // baseline == nil means no comparison context — single-provider rule (absolute threshold only).
    static func warningTime(for time: TimeInterval?, baseline: TimeInterval?) -> TimeInterval? {
        guard let time, time > 0, time > timeWarningThreshold else { return nil }
        guard let baseline, baseline > 0 else { return time }
        return time >= baseline * timeWarningRatio ? time : nil
    }
}
