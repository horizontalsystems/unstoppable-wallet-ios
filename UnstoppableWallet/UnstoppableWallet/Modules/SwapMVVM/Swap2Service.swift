import RxSwift
import RxCocoa
import RxRelay
import HsToolKit
import UniswapKit

class Swap2Service {
    private let disposeBag = DisposeBag()
    private var allowanceDisposable: Disposable?
    private var tradeDataDisposable: Disposable?

    private let uniswapRepository: UniswapRepository
    private let allowanceRepository: AllowanceRepository
    private let swapCoinProvider: SwapCoinProvider
    private let adapterManager: IAdapterManager

    private var estimatedRelay = BehaviorRelay<TradeType>(value: .exactIn)
    private var coinInRelay: BehaviorRelay<Coin>
    private var coinOutRelay = BehaviorRelay<Coin?>(value: nil)

    private var amountInRelay = BehaviorRelay<CoinValue?>(value: nil)
    private var amountOutRelay = BehaviorRelay<CoinValue?>(value: nil)

    private var balanceRelay = BehaviorRelay<CoinValue?>(value: nil)
    private var validationErrorsRelay = BehaviorRelay<[Error]>(value: [])

    private var tradeDataStateRelay = BehaviorRelay<DataStatus<Swap2Module.TradeItem>?>(value: nil)
    private var allowanceStateRelay = BehaviorRelay<DataStatus<CoinValue>?>(value: nil)

    private var swapStateRelay = BehaviorRelay<Swap2Module.SwapState>(value: .idle)

    private var waitingForApprove: Bool = false

    init(uniswapRepository: UniswapRepository, allowanceRepository: AllowanceRepository, swapCoinProvider: SwapCoinProvider, adapterManager: IAdapterManager, coin: Coin) {
        self.uniswapRepository = uniswapRepository
        self.allowanceRepository = allowanceRepository
        self.swapCoinProvider = swapCoinProvider
        self.adapterManager = adapterManager

        coinInRelay = BehaviorRelay(value: coin)

        updateBalance()
        updateAllowance()

        sync()
    }

    private func tryResetCoinOut(coin: Coin) {
        if coinOutRelay.value == coin {
            coinOutRelay.accept(nil)
        }
    }

    private func coin(for type: TradeType) -> Coin? {
        type == .exactIn ? coinInRelay.value : coinOutRelay.value
    }

    private func amount(for type: TradeType) -> Decimal? {
        (type == .exactIn ? amountInRelay : amountOutRelay).value?.value
    }

    private func clearEstimated(for type: TradeType) {
        switch type {
        case .exactIn:
            amountOutRelay.accept(nil)
        case .exactOut:
            amountInRelay.accept(nil)
        }
    }

    private func balance(coin: Coin) -> Decimal? {
        guard let adapter = adapterManager.adapter(for: coin) as? IBalanceAdapter else {
            return nil
        }

        return adapter.balance
    }

    private func updateTradeData(type: TradeType) {
        guard let coinOut = coinOutRelay.value else {

            tradeDataStateRelay.accept(nil)
            return
        }

        let amount = self.amount(for: type) ?? 0

        tradeDataStateRelay.accept(.loading)
        let coinIn = coinInRelay.value

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
        let coin = coinInRelay.value
        guard coin.type != .ethereum else {
            allowanceStateRelay.accept(nil)

            return
        }

        allowanceStateRelay.accept(.loading)

        allowanceDisposable?.dispose()

        allowanceDisposable = allowanceRepository
                .allowanceObservable(coin: coin, spenderAddress: uniswapRepository.spenderAddress)
                .subscribe(onNext: { [weak self] allowance in
                    self?.handle(coin: coin, allowance: allowance)

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
        let coin = coinInRelay.value

        guard let balance = self.balance(coin: coin) else {
            return
        }

        balanceRelay.accept(CoinValue(coin: coin, value: balance))
    }

    private func stateByAllowance() -> Swap2Module.SwapState {
        guard let allowance = allowanceStateRelay.value else {
            return .allowed
        }
        guard let data = allowance.data else {
            return .idle
        }
        if (amount(for: .exactIn) ?? 0) > data.value {
            return .approveRequired
        }
        return .allowed
    }

    private func stateByTradeData(state: Swap2Module.SwapState) -> Swap2Module.SwapState {
        guard let tradeData = tradeDataStateRelay.value else {
            return .idle
        }
        guard let data = tradeData.data else {
            return .idle
        }
        if (data.priceImpact ?? 0) >= 10 {      // TODO: How to isolate logic with create viewItem
            return .idle
        }
        return state
    }

    private func sync() {
        var errors = [Error]()
        var state = stateByAllowance()

        validationErrorsRelay.accept(errors)

        guard let balance = balanceRelay.value else {
            errors.append(SwapValidationError.insufficientBalance(availableBalance: nil))

            validationErrorsRelay.accept(errors)
            swapStateRelay.accept(.idle)
            return
        }

        if (amount(for: .exactIn) ?? 0) > balance.value {
            errors.append(SwapValidationError.insufficientBalance(availableBalance: balance))
            state = .idle
        }

        if let allowance = allowanceStateRelay.value?.data,
           (amount(for: .exactIn) ?? 0) > allowance.value {
            errors.append(SwapValidationError.insufficientAllowance)
        }

        if waitingForApprove {
            state = .waitingForApprove
        } else {
            state = stateByTradeData(state: state)
        }

        validationErrorsRelay.accept(errors)
        swapStateRelay.accept(state)
    }

}

extension Swap2Service {

    private func handle(tradeData: TradeData, coinIn: Coin, coinOut: Coin) {
        let estimatedAmount = tradeData.type == .exactIn ? tradeData.amountOut : tradeData.amountIn
        switch tradeData.type {
        case .exactIn:
            let amount = estimatedAmount.map { CoinValue(coin: coinOut, value: $0) }
            amountOutRelay.accept(amount)
        case .exactOut:
            let amount = tradeData.amountIn.map { CoinValue(coin: coinIn, value: $0) }
            amountInRelay.accept(amount)
        }

        let tradeItem = Swap2Module.TradeItem(
                coinIn: coinIn,
                coinOut: coinOut,
                type: tradeData.type,
                executionPrice: tradeData.executionPrice,
                priceImpact: tradeData.priceImpact,
                minMaxAmount: tradeData.type == .exactIn ? tradeData.amountOutMin : tradeData.amountInMax)

        tradeDataStateRelay.accept(.completed(tradeItem))

        sync()
    }

    private func handle(coin: Coin, allowance: Decimal) {
        if let lastAllowance = allowanceStateRelay.value?.data,
           allowance != lastAllowance.value {

            waitingForApprove = false
        }

        allowanceStateRelay.accept(.completed(CoinValue(coin: coin, value: allowance)))
    }

}

extension Swap2Service {

    func tokensForSelection(type: TradeType) -> [CoinBalanceItem] {
        switch type {
        case .exactIn: return swapCoinProvider.coins(accountCoins: true, exclude: [])
        case .exactOut: return swapCoinProvider.coins(accountCoins: false, exclude: [coinInRelay.value])
        }
    }

    func onChange(type: TradeType, amount: Decimal?) {
        estimatedRelay.accept(type)
        clearEstimated(for: type)

        switch type {
        case .exactIn:
            let coinValue = amount.map { CoinValue(coin: coinInRelay.value, value: $0) }
            amountInRelay.accept(coinValue)
        case .exactOut:
            let coinValue = coinOutRelay.value.flatMap { coin in amount.map { CoinValue(coin: coin, value: $0) } }
            amountOutRelay.accept(coinValue)
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
            coinInRelay.accept(coin)
            updateBalance()
            updateAllowance()

            tryResetCoinOut(coin: coin)
        case .exactOut:
            coinOutRelay.accept(coin)
        }

        clearEstimated(for: estimatedRelay.value)

        waitingForApprove = false
        updateTradeData(type: estimatedRelay.value)

        sync()
    }

    func didApprove() {
        waitingForApprove = true

        sync()
    }

    var approveData: Swap2Module.ApproveData? {
        guard let amount = amount(for: .exactIn) else {
            return nil
        }
        return Swap2Module.ApproveData(coin: coinInRelay.value,
                spenderAddress: uniswapRepository.spenderAddress,
                amount: amount)
    }

    var proceedData: Swap2Module.ProceedData {
        Swap2Module.ProceedData()
    }

    var estimated: Observable<TradeType> {
        estimatedRelay.asObservable()
    }

    var coinIn: Observable<Coin> {
        coinInRelay.asObservable()
    }

    var coinOut: Observable<Coin?> {
        coinOutRelay.asObservable()
    }

    var amountIn: Observable<CoinValue?> {
        amountInRelay.asObservable()
    }

    var amountOut: Observable<CoinValue?> {
        amountOutRelay.asObservable()
    }

    var balance: Observable<CoinValue?> {
        balanceRelay.asObservable()
    }

    var validationErrors: Observable<[Error]> {
        validationErrorsRelay.asObservable()
    }

    var allowance: Observable<DataStatus<CoinValue>?> {
        allowanceStateRelay.asObservable()
    }

    var tradeData: Observable<DataStatus<Swap2Module.TradeItem>?> {
        tradeDataStateRelay.asObservable()
    }

    var swapState: Observable<Swap2Module.SwapState> {
        swapStateRelay.asObservable()
    }

}
