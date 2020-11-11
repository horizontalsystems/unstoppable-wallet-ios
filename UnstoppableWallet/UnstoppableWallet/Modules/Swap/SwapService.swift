import RxSwift
import RxCocoa
import RxRelay
import HsToolKit
import UniswapKit
import CurrencyKit
import BigInt

class SwapService {
    private static let refreshInterval: TimeInterval = 10
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
    private var coinInRelay = PublishRelay<Coin?>()
    private var coinOutRelay = PublishRelay<Coin?>()

    private var amountInRelay = PublishRelay<Decimal?>()
    private var amountOutRelay = PublishRelay<Decimal?>()

    private var balanceInRelay = BehaviorRelay<Decimal?>(value: nil)
    private var balanceOutRelay = BehaviorRelay<Decimal?>(value: nil)
    private var validationErrorsRelay = BehaviorRelay<[Error]>(value: [])

    private var tradeDataStateRelay = PublishRelay<DataStatus<SwapModule.TradeItem>?>()
    private var allowanceStateRelay = BehaviorRelay<DataStatus<Decimal>?>(value: nil)
    private var feeStateRelay = PublishRelay<DataStatus<SwapModule.SwapFeeInfo>?>()

    private var swapStateRelay = BehaviorRelay<DataStatus<Data>?>(value: nil)
    private var stateRelay = BehaviorRelay<SwapModule.SwapState>(value: .idle)

    private var tradeData: TradeData?
    var tradeOptions: TradeOptions = TradeOptions()

    private var approvingTimer: Timer?
    private var lastAllowance: Decimal?

    private(set) var estimated = TradeType.exactIn {
        didSet {
            estimatedRelay.accept(estimated)
        }
    }

    private(set) var coinIn: Coin? {
        didSet {
            coinInRelay.accept(coinIn)

            lastAllowance = nil
            updateAllowance()
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

    private(set) var balanceIn: Decimal? {
        didSet {
            balanceInRelay.accept(balanceIn)
        }
    }

    private(set) var balanceOut: Decimal? {
        didSet {
            balanceOutRelay.accept(balanceOut)
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

        updateBalances()
        updateAllowance()

        sync()
    }

    private func startWaitingApprove() {
        guard approvingTimer == nil else {
            return
        }

        approvingTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.updateAllowance()
        }

        updateAllowance()
    }

    private func stopWaitingApprove() {
        if approvingTimer != nil {
            approvingTimer?.invalidate()
            approvingTimer = nil
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

    private func insufficientAllowance() -> Bool {
        if let allowance = allowanceStateRelay.value?.data,
           (allowanceAmount(for: estimated) ?? 0) > allowance {     // not enough allowance for swap
            return true
        }
        return false
    }

    private func clearEstimated(for type: TradeType) {
        switch type {
        case .exactIn:
            amountOut = nil
        case .exactOut:
            amountIn = nil
        }
    }

    private func balance(coin: Coin?) -> Decimal? {
        guard let coin = coin, let adapter = adapterManager.adapter(for: coin) as? IBalanceAdapter else {
            return nil
        }

        return adapter.balance
    }

    private func updateFeeState() {
        guard let coinIn = coinIn, let tradeData = tradeData else {
            feeState = nil
            return
        }

        if allowanceStateRelay.value != nil, insufficientAllowance() {    // for erc20 without allowance(or loading) can't calculate fee
            feeState = nil
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
    }

    private func updateTradeData() {
        guard let coinIn = coinIn, let coinOut = coinOut else {

            tradeDataState = nil
            return
        }

        let amount = self.amount(for: estimated) ?? 0

        tradeDataDisposable?.dispose()

        tradeDataState = .loading
        tradeDataDisposable = uniswapRepository
                .trade(coinIn: coinIn, coinOut: coinOut, amount: amount, tradeType: estimated, tradeOptions: TradeOptions())
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

        guard let coinIn = self.coinIn, coinIn.type != .ethereum else {
            allowanceStateRelay.accept(nil)

            return
        }

        allowanceStateRelay.accept(.loading)
        allowanceDisposable = allowanceProvider
                .allowanceObservable(coin: coinIn, spenderAddress: uniswapRepository.routerAddress)
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.handle(allowance: allowance, coin: coinIn)
                }, onError: { [weak self] error in
                    self?.stopWaitingApprove()
                    self?.allowanceStateRelay.accept(.failed(error))

                    self?.sync()
                })

        allowanceDisposable?.disposed(by: disposeBag)
    }

    private func updateBalances() {
        self.balanceIn = self.balance(coin: coinIn)
        self.balanceOut = self.balance(coin: coinOut)
    }

    private func sync() {
        guard let coinIn = coinIn else {        // not select coin in. Just idle
            stateRelay.accept(.idle)
            return
        }

        guard let balanceIn = balanceIn else {      // can't get balance for coinIn. Idle and N/A for balanceIn
            validationErrorsRelay.accept([SwapValidationError.unavailableBalance(type: .exactIn)])
            stateRelay.accept(.idle)
            return
        }

        var errors = [Error]()

        if let allowanceError = allowanceStateRelay.value?.error {  // can't get allowance
            errors.append(allowanceError)
        }

        if (amount(for: .exactIn) ?? 0) > balanceIn {   // not enough balance for swap
            errors.append(SwapValidationError.insufficientBalance)
        }

        if let fee = feeState?.data,
           fee.coinAmount.coin == coinIn,
           let amount = amount(for: .exactIn),
           amount + fee.coinAmount.value > balanceIn {  // not enough balance+fee (for Eth) for swap

            errors.append(FeeModule.FeeError.insufficientFeeBalance(coinValue: fee.coinAmount))
        }
        if let feeError = feeState?.error {     // can't get fee for swap
            errors.append(feeError)
        }

        let hasErrors = !errors.isEmpty
        if insufficientAllowance() {     // not enough allowance for swap
            errors.append(SwapValidationError.insufficientAllowance)
        }

        if hasErrors {
            validationErrorsRelay.accept(errors)
            stateRelay.accept(.idle)
            return
        }

        if approvingTimer != nil {
            validationErrorsRelay.accept(errors)
            stateRelay.accept(.waitingForApprove)
            return
        }

        var state = SwapModule.SwapState.idle
        let forbiddenTrade = tradeDataState?.data?.priceImpactLevel == .forbidden

        if tradeDataState?.data != nil,
           feeState?.data != nil,
           !forbiddenTrade {

            state = .proceedAllowed
        }

        if let allowanceData = allowanceStateRelay.value {
            let needed = allowanceAmount(for: estimated) ?? 0

            switch allowanceData {
            case .completed(let allowance): state = needed > allowance && !forbiddenTrade ? .approveRequired : state
            default: state = .idle
            }
        }

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
        updateFeeState()

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
                providerFee: tradeData.providerFee,
                minMaxAmount: tradeData.type == .exactIn ? tradeData.amountOutMin : tradeData.amountInMax)

        tradeDataState = .completed(tradeItem)

        sync()
    }

    private func handle(allowance: Decimal, coin: Coin) {
        if let lastAllowance = lastAllowance,
           allowance == lastAllowance {

            let newState: DataStatus<Decimal> = stateRelay.value == .waitingForApprove ? .loading : .completed(allowance)
            allowanceStateRelay.accept(newState)
            return
        }

        allowanceStateRelay.accept(.completed(allowance))
        stopWaitingApprove()

        self.lastAllowance = allowance
        sync()
    }

}

extension SwapService {

    func tokensForSelection(type: TradeType) -> [SwapModule.CoinBalanceItem] {
        switch type {
        case .exactIn: return swapCoinProvider.coins(accountCoins: true, exclude: [])
        case .exactOut: return swapCoinProvider.coins(accountCoins: false, exclude: [])
        }
    }

    func onChange(type: TradeType, amount: Decimal?) {
        estimated = type

        guard self.amount(for: type) != amount else {
            return
        }

        clearEstimated(for: type)

        switch type {
        case .exactIn:
            amountIn = amount
        case .exactOut:
            amountOut = amount
        }

        stopWaitingApprove()
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

            if coinOut == coin {
                coinOut = nil
            }
        case .exactOut:
            coinOut = coin

            if coinIn == coin {
                coinIn = nil
            }
        }
        updateBalances()

        clearEstimated(for: estimated)

        stopWaitingApprove()
        feeState = nil
        updateTradeData()

        sync()
    }

    func didApprove() {
        startWaitingApprove()

        sync()
    }

    func proceed() {
    }

    func switchCoins() {
        let swapCoin = coinIn
        coinIn = coinOut
        coinOut = swapCoin

        updateBalances()

        clearEstimated(for: estimated)

        stopWaitingApprove()
        feeState = nil
        updateTradeData()

        sync()
    }

    func swap() {
        guard let tradeData = tradeData,
              let feeData = feeState?.data else {
            return
        }

        swapStateRelay.accept(.loading)
        swapDisposable?.dispose()

        self.swapStateRelay.accept(.completed(Data()))
        self.stateRelay.accept(.swapSuccess)
//        swapDisposable = uniswapRepository
//                .swap(tradeData: tradeData, gasLimit: feeData.gasLimit, gasPrice: feeData.gasPrice)
//                .subscribe(onSuccess: { [weak self] _ in
//                    self?.swapStateRelay.accept(.completed(Data()))
//
//                    self?.stateRelay.accept(.swapSuccess)
//                }, onError: { [weak self] error in
//                    self?.swapStateRelay.accept(.failed(error))
//                })

        swapDisposable?.disposed(by: disposeBag)
    }

    var approveData: SwapModule.ApproveData? {
        guard let coinIn = coinIn, let amount = allowanceAmount(for: estimated) else {
            return nil
        }
        let allowance = allowanceStateRelay.value?.data ?? 0

        return SwapModule.ApproveData(coin: coinIn,
                spenderAddress: uniswapRepository.routerAddress,
                amount: BigUInt(amount.roundedString(decimal: coinIn.decimal)) ?? 0,
                allowance: BigUInt(allowance.roundedString(decimal: coinIn.decimal)) ?? 0)
    }

    var estimatedObservable: Observable<TradeType> {
        estimatedRelay.asObservable()
    }

    var coinInObservable: Observable<Coin?> {
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

    var balanceInObservable: Observable<Decimal?> {
        balanceInRelay.asObservable()
    }

    var balanceOutObservable: Observable<Decimal?> {
        balanceOutRelay.asObservable()
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
