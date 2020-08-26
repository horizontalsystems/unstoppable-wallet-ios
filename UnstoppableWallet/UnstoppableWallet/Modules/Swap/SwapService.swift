import RxSwift
import RxCocoa
import RxRelay
import HsToolKit
import UniswapKit

class SwapService {
    private static let warningPriceImpact: Decimal = 1
    private static let forbiddenPriceImpact: Decimal = 5

    private let disposeBag = DisposeBag()
    private var allowanceDisposable: Disposable?
    private var tradeDataDisposable: Disposable?
    private var swapDisposable: Disposable?

    private let uniswapRepository: UniswapRepository
    private let allowanceRepository: AllowanceRepository
    private let swapCoinProvider: SwapCoinProvider
    private let adapterManager: IAdapterManager

    private var estimatedRelay = PublishRelay<TradeType>()
    private var coinInRelay = PublishRelay<Coin>()
    private var coinOutRelay = PublishRelay<Coin?>()

    private var amountInRelay = PublishRelay<Decimal?>()
    private var amountOutRelay = PublishRelay<Decimal?>()

    private var balanceRelay = BehaviorRelay<Decimal?>(value: nil)
    private var validationErrorsRelay = BehaviorRelay<[Error]>(value: [])

    private var tradeDataStateRelay = PublishRelay<DataStatus<SwapModule.TradeItem>?>()
    private var allowanceStateRelay = BehaviorRelay<DataStatus<Decimal>?>(value: nil)

    private var swapStateRelay = BehaviorRelay<DataStatus<Data>?>(value: nil)
    private var stateRelay = BehaviorRelay<SwapModule.SwapState>(value: .idle)

    private var tradeData: TradeData?
    private var waitingForApprove: Bool = false

    public var estimated = TradeType.exactIn {
        didSet {
            estimatedRelay.accept(estimated)
        }
    }

    public var coinIn: Coin {
        didSet {
            coinInRelay.accept(coinIn)
        }
    }

    public var coinOut: Coin? {
        didSet {
            coinOutRelay.accept(coinOut)
        }
    }

    public var amountIn: Decimal? {
        didSet {
            amountInRelay.accept(amountIn)
        }
    }

    public var amountOut: Decimal? {
        didSet {
            amountOutRelay.accept(amountOut)
        }
    }

    public var balance: Decimal? {
        didSet {
            balanceRelay.accept(balance)
        }
    }

    public var tradeDataState: DataStatus<SwapModule.TradeItem>? {
        didSet {
            tradeDataStateRelay.accept(tradeDataState)
        }
    }

    init(uniswapRepository: UniswapRepository, allowanceRepository: AllowanceRepository, swapCoinProvider: SwapCoinProvider, adapterManager: IAdapterManager, coin: Coin) {
        self.uniswapRepository = uniswapRepository
        self.allowanceRepository = allowanceRepository
        self.swapCoinProvider = swapCoinProvider
        self.adapterManager = adapterManager

        coinIn = coin

        updateBalance()
        updateAllowance()

        sync()
    }

    private func tryResetCoinOut(coin: Coin) {
        if coinOut == coin {
            coinOut = coin
        }
    }

    private func coin(for type: TradeType) -> Coin? {
        type == .exactIn ? coinIn : coinOut
    }

    private func amount(for type: TradeType) -> Decimal? {
        type == .exactIn ? amountIn : amountOut
    }

    private func clearEstimated(for type: TradeType) {
        switch type {
        case .exactIn:
            amountOut = nil
        case .exactOut:
            amountIn = nil
        }
    }

    private func balance(coin: Coin) -> Decimal? {
        guard let adapter = adapterManager.adapter(for: coin) as? IBalanceAdapter else {
            return nil
        }

        return adapter.balance
    }

    private func updateTradeData(type: TradeType) {
        let coinIn = self.coinIn
        guard let coinOut = coinOut else {

            tradeDataState = nil
            return
        }

        let amount = self.amount(for: type) ?? 0

        tradeDataState = .loading

        tradeDataDisposable?.dispose()
        tradeDataDisposable = uniswapRepository
                .trade(coinIn: coinIn, coinOut: coinOut, amount: amount, tradeType: type)
                .subscribe(onSuccess: { [weak self] item in
                    self?.handle(tradeData: item, coinIn: coinIn, coinOut: coinOut)
                }, onError: { [weak self] error in
                    self?.tradeDataStateRelay.accept(.failed(error))

                    self?.sync()
                })

        tradeDataDisposable?.disposed(by: disposeBag)
    }

    private func updateAllowance() {
        let coinIn = self.coinIn
        guard coinIn.type != .ethereum else {
            allowanceStateRelay.accept(nil)
            allowanceDisposable?.dispose()

            return
        }

        allowanceStateRelay.accept(.loading)

        allowanceDisposable?.dispose()

        allowanceDisposable = allowanceRepository
                .allowanceObservable(coin: coinIn, spenderAddress: uniswapRepository.spenderAddress)
                .subscribe(onNext: { [weak self] allowance in
                    self?.handle(coin: coinIn, allowance: allowance)

                    self?.sync()
                }, onError: { [weak self] error in
                    self?.waitingForApprove = false
                    self?.allowanceStateRelay.accept(.failed(error))

                    self?.sync()
                })

        allowanceDisposable?.disposed(by: disposeBag)
    }

    private func updateEthereumBalance() {

    }

    private func updateBalance() {
        guard let balance = self.balance(coin: coinIn) else {
            return
        }

        self.balance = balance
    }

    private func stateByAllowance() -> SwapModule.SwapState? {
        guard let allowance = allowanceStateRelay.value else {
            return nil
        }
        guard let data = allowance.data else {
            return .idle
        }
        if (amount(for: .exactIn) ?? 0) > data {
            return .approveRequired
        }
        return nil
    }

    private func stateByTradeData() -> SwapModule.SwapState {
        guard let tradeData = tradeDataState else {
            return .idle
        }
        guard let data = tradeData.data else {
            return .idle
        }

        if data.priceImpactLevel == .forbidden {
            return .idle
        }
        return .allowed
    }

    private func sync() {
        var errors = [Error]()

        guard let balance = balance else {
            errors.append(SwapValidationError.insufficientBalance(availableBalance: nil))

            validationErrorsRelay.accept(errors)
            stateRelay.accept(.idle)
            return
        }

        var state = stateByTradeData()
        validationErrorsRelay.accept(errors)

        if (amount(for: .exactIn) ?? 0) > balance {
            errors.append(SwapValidationError.insufficientBalance(availableBalance: CoinValue(coin: coinIn, value: balance)))
            state = .idle
        }

        if let allowance = allowanceStateRelay.value?.data,
           (amount(for: .exactIn) ?? 0) > allowance {
            errors.append(SwapValidationError.insufficientAllowance)
        }

        if waitingForApprove {
            state = .waitingForApprove
        } else {
            state = stateByAllowance() ?? state
        }

        validationErrorsRelay.accept(errors)
        stateRelay.accept(state)
    }

}

extension SwapService {

    private func handle(tradeData: TradeData, coinIn: Coin, coinOut: Coin) {
        self.tradeData = tradeData

        let estimatedAmount = tradeData.type == .exactIn ? tradeData.amountOut : tradeData.amountIn
        switch tradeData.type {
        case .exactIn:
            amountOut = estimatedAmount
        case .exactOut:
            amountIn = estimatedAmount
        }

        var impactLevel = SwapModule.PriceImpactLevel.none
        if let priceImpact = tradeData.priceImpact {
            switch priceImpact {
            case 0..<SwapService.warningPriceImpact: impactLevel = .normal
            case SwapService.warningPriceImpact..<SwapService.forbiddenPriceImpact: impactLevel = .warning
            default: impactLevel = .forbidden
            }
        }

        let tradeItem = SwapModule.TradeItem(
                coinIn: coinIn,
                coinOut: coinOut,
                type: tradeData.type,
                executionPrice: tradeData.executionPrice,
                priceImpact: tradeData.priceImpact,
                priceImpactLevel: impactLevel,
                minMaxAmount: tradeData.type == .exactIn ? tradeData.amountOutMin : tradeData.amountInMax)

        tradeDataState = .completed(tradeItem)

        sync()
    }

    private func handle(coin: Coin, allowance: Decimal) {
        if let lastAllowance = allowanceStateRelay.value?.data,
           allowance != lastAllowance {

            waitingForApprove = false
        }

        allowanceStateRelay.accept(.completed(allowance))
    }

}

extension SwapService {

    func tokensForSelection(type: TradeType) -> [SwapModule.CoinBalanceItem] {
        switch type {
        case .exactIn: return swapCoinProvider.coins(accountCoins: true, exclude: [])
        case .exactOut: return swapCoinProvider.coins(accountCoins: false, exclude: [coinIn])
        }
    }

    func onChange(type: TradeType, amount: Decimal?) {
        estimated = type
        clearEstimated(for: type)

        switch type {
        case .exactIn:
            amountIn = amount
        case .exactOut:
            amountOut = amount
        }

        waitingForApprove = false
        updateTradeData(type: type)

        sync()
    }

    func onSelect(type: TradeType, coin: Coin) {
        guard self.coin(for: type) != coin else {
            return
        }

        switch type {
        case .exactIn:
            coinIn = coin

            updateBalance()
            updateAllowance()

            tryResetCoinOut(coin: coin)
        case .exactOut:
            coinOut = coin
        }

        clearEstimated(for: estimated)

        waitingForApprove = false
        updateTradeData(type: estimated)

        sync()
    }

    func didApprove() {
        waitingForApprove = true

        sync()
    }

    func swap() {
        guard let tradeData = tradeData else {
            return
        }

        swapStateRelay.accept(.loading)
        swapDisposable?.dispose()

        swapDisposable = uniswapRepository
                .swap(tradeData: tradeData, gasLimit: 1000000, gasPrice: 90)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.swapStateRelay.accept(.completed(Data()))

                    self?.stateRelay.accept(.swapSuccess)
                }, onError: { [weak self] error in
                    self?.swapStateRelay.accept(.failed(error))
                })

        swapDisposable?.disposed(by: disposeBag)
    }

    var approveData: SwapModule.ApproveData? {
        guard let amount = amount(for: .exactIn) else {
            return nil
        }
        return SwapModule.ApproveData(coin: coinIn,
                spenderAddress: uniswapRepository.spenderAddress,
                amount: amount)
    }

    var estimatedObservable: Observable<TradeType> {
        estimatedRelay.asObservable()
    }

    var coinInObservable: Observable<Coin> {
        coinInRelay.asObservable()
    }

    var coinOutObservable: Observable<Coin?> {
        coinOutRelay.asObservable()
    }

    var amountInObservable: Observable<Decimal?> {
        amountInRelay.asObservable()
    }

    var amountOutObservable: Observable<Decimal?> {
        amountOutRelay.asObservable()
    }

    var balanceObservable: Observable<Decimal?> {
        balanceRelay.asObservable()
    }

    var validationErrorsObservable: Observable<[Error]> {
        validationErrorsRelay.asObservable()
    }

    var allowanceObservable: Observable<DataStatus<Decimal>?> {
        allowanceStateRelay.asObservable()
    }

    var tradeDataObservable: Observable<DataStatus<SwapModule.TradeItem>?> {
        tradeDataStateRelay.asObservable()
    }

    var stateObservable: Observable<SwapModule.SwapState> {
        stateRelay.asObservable()
    }

    var swapStateObservable: Observable<DataStatus<Data>?> {
        swapStateRelay.asObservable()
    }

}
