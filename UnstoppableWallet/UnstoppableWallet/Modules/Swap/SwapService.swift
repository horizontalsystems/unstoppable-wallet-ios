import RxSwift
import RxCocoa
import RxRelay
import HsToolKit
import UniswapKit
import CurrencyKit

class SwapService {
    static private let refreshInterval: TimeInterval = 10
    private static let warningPriceImpact: Decimal = 1
    private static let forbiddenPriceImpact: Decimal = 5

    private let disposeBag = DisposeBag()
    private var allowanceDisposable: Disposable?
    private var tradeDataDisposable: Disposable?
    private var swapDisposable: Disposable?
    private var feeDisposable: Disposable?

    private let uniswapRepository: UniswapRepository
    private let allowanceProvider: AllowanceProvider
    private let swapFeeRepository: SwapFeeRepository
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
    private var feeStateRelay = PublishRelay<DataStatus<SwapModule.SwapFeeInfo>?>()

    private var swapStateRelay = BehaviorRelay<DataStatus<Data>?>(value: nil)
    private var stateRelay = BehaviorRelay<SwapModule.SwapState>(value: .idle)

    private var tradeData: TradeData?
    private var waitingForApprove: Bool = false
    private var timer: Timer?

    private(set) var estimated = TradeType.exactIn {
        didSet {
            estimatedRelay.accept(estimated)
        }
    }

    private(set) var coinIn: Coin {
        didSet {
            coinInRelay.accept(coinIn)
        }
    }

    private(set) var coinOut: Coin? {
        didSet {
            coinOutRelay.accept(coinOut)
        }
    }

    private(set) var amountIn: Decimal? {
        didSet {
            amountInRelay.accept(amountIn)
        }
    }

    private(set) var amountOut: Decimal? {
        didSet {
            amountOutRelay.accept(amountOut)
        }
    }

    private(set) var balance: Decimal? {
        didSet {
            balanceRelay.accept(balance)
        }
    }

    private(set) var tradeDataState: DataStatus<SwapModule.TradeItem>? {
        didSet {
            tradeDataStateRelay.accept(tradeDataState)
        }
    }

    private(set) var feeState: DataStatus<SwapModule.SwapFeeInfo>? {
        didSet {
            feeStateRelay.accept(feeState)
        }
    }

    var feePriority: FeeRatePriority { swapFeeRepository.priority }

    init(uniswapRepository: UniswapRepository, allowanceRepository: AllowanceProvider, swapFeeRepository: SwapFeeRepository, swapCoinProvider: SwapCoinProvider, adapterManager: IAdapterManager, coin: Coin) {
        self.uniswapRepository = uniswapRepository
        self.allowanceProvider = allowanceRepository
        self.swapFeeRepository = swapFeeRepository
        self.swapCoinProvider = swapCoinProvider
        self.adapterManager = adapterManager

        coinIn = coin

        subscribeToService()
        updateBalance()
        updateAllowance()

        sync()
    }

    private func subscribeToService() {
        timer = Timer.scheduledTimer(timeInterval: Self.refreshInterval, target: self, selector: #selector(handleRefreshTimer), userInfo: nil, repeats: true)
    }

    @objc private func handleRefreshTimer() {
        guard waitingForApprove else {
            return
        }

        updateAllowance()
    }

    private func tryResetCoinOut(coin: Coin) {
        if coinOut == coin {
            coinOut = nil
        }
    }

    private func coin(for type: TradeType) -> Coin? {
        type == .exactIn ? coinIn : coinOut
    }

    private func amount(for type: TradeType) -> Decimal? {
        type == .exactIn ? amountIn : amountOut
    }

    private func allowanceAmount(for type: TradeType) -> Decimal? {
        type == .exactIn ? amountIn : tradeData?.amountInMax
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

    private func updateTradeData() {
        let coinIn = self.coinIn
        guard let coinOut = coinOut else {

            tradeDataState = nil
            return
        }

        let amount = self.amount(for: estimated) ?? 0

        tradeDataState = .loading

        tradeDataDisposable?.dispose()
        tradeDataDisposable = uniswapRepository
                .trade(coinIn: coinIn, coinOut: coinOut, amount: amount, tradeType: estimated)
                .subscribe(onSuccess: { [weak self] item in
                    self?.handle(tradeData: item, coinIn: coinIn, coinOut: coinOut)
                }, onError: { [weak self] error in
                    self?.tradeDataState = .failed(error)

                    self?.sync()
                })

        tradeDataDisposable?.disposed(by: disposeBag)
    }

    private func updateAllowance() {
        allowanceDisposable?.dispose()

        let coinIn = self.coinIn
        guard coinIn.type != .ethereum else {
            allowanceStateRelay.accept(nil)

            return
        }

        let last = allowanceStateRelay.value?.data

        allowanceStateRelay.accept(.loading)
        allowanceDisposable = allowanceProvider
                .allowanceObservable(coin: coinIn, spenderAddress: uniswapRepository.routerAddress)
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.handle(lastAllowance: last, allowance: allowance, coin: coinIn)
                }, onError: { [weak self] error in
                    self?.waitingForApprove = false
                    self?.allowanceStateRelay.accept(.failed(error))

                    self?.sync()
                })

        allowanceDisposable?.disposed(by: disposeBag)
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
        if (allowanceAmount(for: estimated) ?? 0) > data {
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
        return .proceedAllowed
    }

    private func stateByFee() -> SwapModule.SwapState? {
        guard let feeState = feeState else {
            return nil
        }
        if feeState.isLoading {
            return .fetchingFee
        }
        if feeState.error != nil {
            return .idle
        }
        if feeState.data != nil {
            return .swapAllowed
        }

        return nil
    }

    private func sync() {
        guard let balance = balance else {
            validationErrorsRelay.accept([SwapValidationError.insufficientBalance(availableBalance: nil)])
            stateRelay.accept(.idle)
            return
        }
        var errors = [Error]()

        if let allowanceError = allowanceStateRelay.value?.error {
            errors.append(allowanceError)
        }
        if (amount(for: .exactIn) ?? 0) > balance {
            errors.append(SwapValidationError.insufficientBalance(availableBalance: CoinValue(coin: coinIn, value: balance)))
        }
        if let fee = feeState?.data,
           fee.coinAmount.coin == coinIn,
           let amount = amount(for: .exactIn),
           amount + fee.coinAmount.value > balance {

            let coinValue = CoinValue(coin: fee.coinAmount.coin, value: amount + fee.coinAmount.value)
            errors.append(FeeModule.FeeError.insufficientAmountWithFeeBalance(coinValue: coinValue))
        }
        if let feeError = feeState?.error {
            errors.append(feeError)
        }

        let hasErrors = !errors.isEmpty
        if let allowance = allowanceStateRelay.value?.data,
           (allowanceAmount(for: estimated) ?? 0) > allowance {
            errors.append(SwapValidationError.insufficientAllowance)
        }

        if hasErrors {
            validationErrorsRelay.accept(errors)
            stateRelay.accept(.idle)
            return
        }

        if waitingForApprove {
            validationErrorsRelay.accept(errors)
            stateRelay.accept(.waitingForApprove)
            return
        }

        var state = stateByTradeData()

        state = stateByAllowance() ?? state     // check allowance
        state = stateByFee() ?? state           // check fee

        validationErrorsRelay.accept(errors)

        guard stateRelay.value != state else {
            return
        }

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

    private func handle(lastAllowance: Decimal?, allowance: Decimal, coin: Coin) {
        if let lastAllowance = lastAllowance,
           allowance == lastAllowance {

            allowanceStateRelay.accept(.completed(allowance))
            return
        }

        allowanceStateRelay.accept(.completed(allowance))
        waitingForApprove = false
        sync()
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
        feeState = nil
        updateTradeData()

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
        feeState = nil
        updateTradeData()

        sync()
    }

    func didApprove() {
        waitingForApprove = true

        sync()
    }

    func proceed() {
        guard let tradeData = tradeData else {
            return
        }
        feeDisposable?.dispose()

        feeState = .loading
        feeDisposable = swapFeeRepository.swapFeeInfo(coin: coinIn, tradeData: tradeData)
        .subscribe(onSuccess: { [weak self] info in
            self?.feeState = .completed(info)
            self?.sync()
        }, onError: { [weak self] error in
            self?.feeState = .failed(error)
            self?.sync()
        })
        feeDisposable?.disposed(by: disposeBag)

        sync()
    }

    func swap() {
        guard let tradeData = tradeData,
              let feeData = feeState?.data else {
            return
        }

        swapStateRelay.accept(.loading)
        swapDisposable?.dispose()

        swapDisposable = uniswapRepository
                .swap(tradeData: tradeData, gasLimit: feeData.gasLimit, gasPrice: feeData.gasPrice)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.swapStateRelay.accept(.completed(Data()))

                    self?.stateRelay.accept(.swapSuccess)
                }, onError: { [weak self] error in
                    self?.swapStateRelay.accept(.failed(error))
                })

        swapDisposable?.disposed(by: disposeBag)
    }

    var approveData: SwapModule.ApproveData? {
        guard let amount = allowanceAmount(for: estimated) else {
            return nil
        }
        return SwapModule.ApproveData(coin: coinIn,
                spenderAddress: uniswapRepository.routerAddress,
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

    var feeStateObservable: Observable<DataStatus<SwapModule.SwapFeeInfo>?> {
        feeStateRelay.asObservable()
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
