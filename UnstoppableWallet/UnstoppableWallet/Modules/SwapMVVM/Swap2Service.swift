import RxSwift
import RxCocoa
import RxRelay
import HsToolKit
import UniswapKit

class Swap2Service {
    private let disposeBag = DisposeBag()
    private let maxCoinDecimal = 8

    private let uniswapRepository: UniswapRepository
    private let allowanceRepository: AllowanceRepository
    private let adapterManager: IAdapterManager
    private let decimalParser: ISendAmountDecimalParser

    private var estimatedRelay = BehaviorRelay<TradeType>(value: .exactIn)
    private var coinInRelay: BehaviorRelay<Coin>
    private var coinOutRelay = BehaviorRelay<Coin?>(value: nil)

    private var _amountIn: Decimal? = nil
    private var _amountOut: Decimal? = nil

    private var amountInRelay = BehaviorRelay<Decimal?>(value: nil)
    private var amountOutRelay = BehaviorRelay<Decimal?>(value: nil)

    private var balanceRelay = BehaviorRelay<Swap2Module.CoinWithBalance?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var tradeDataState = BehaviorRelay<DataStatus<Swap2Module.TradeItem>?>(value: nil)
    private var allowanceState = BehaviorRelay<DataStatus<Swap2Module.AllowanceItem>?>(value: nil)

    private var actionType = BehaviorRelay<Swap2Module.ActionType>(value: .proceed)
    private var actionEnabled = BehaviorRelay<Bool>(value: false)

    init(uniswapRepository: UniswapRepository, allowanceRepository: AllowanceRepository, adapterManager: IAdapterManager, decimalParser: ISendAmountDecimalParser, coin: Coin) {
        self.uniswapRepository = uniswapRepository
        self.allowanceRepository = allowanceRepository
        self.adapterManager = adapterManager
        self.decimalParser = decimalParser

        coinInRelay = BehaviorRelay(value: coin)

        updateBalance()
        updateAllowance()
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
        type == .exactIn ? _amountIn : _amountOut
    }

    private func balance(coin: Coin) -> Decimal? {
        guard let adapter = adapterManager.adapter(for: coin) as? IBalanceAdapter else {
            return nil
        }

        return adapter.balance
    }

    private func allowanceItem(allowance: Decimal) -> Swap2Module.AllowanceItem {
        let isSufficient = _amountIn ?? 0 < allowance

        return Swap2Module.AllowanceItem(coin: coinInRelay.value, amount: allowance, isSufficient: isSufficient)
    }

    private func updateTradeData(type: TradeType) {
        guard let coinOut = coinOutRelay.value,
              let amount = amount(for: type) else {

            tradeDataState.accept(nil)
            return
        }

        tradeDataState.accept(.loading)
        uniswapRepository
                .trade(coinIn: coinInRelay.value, coinOut: coinOut, amount: amount, tradeType: type)
                .subscribe(onSuccess: { [weak self] item in
                    self?.tradeDataState.accept(.completed(item))
                }, onError: { [weak self] error in
                    self?.tradeDataState.accept(.failed(error))
                })
                .disposed(by: disposeBag)
    }

    private func updateAllowance() {
        let coin = coinInRelay.value
        guard coin.type != .ethereum else {
            allowanceState.accept(nil)
            return
        }

        allowanceState.accept(.loading)
        allowanceRepository
                .allowanceSingle(coin: coin, spenderAddress: uniswapRepository.spenderAddress)
                .subscribe(onSuccess: { [weak self] allowance in
                    if let item = self?.allowanceItem(allowance: allowance) {
                        self?.allowanceState.accept(.completed(item))
                    }
                }, onError: { [weak self] error in
                    self?.allowanceState.accept(.failed(error))
                })
                .disposed(by: disposeBag)
    }

    private func updateBalance() {
        let coin = coinInRelay.value
        guard let balance = self.balance(coin: coin) else {
            balanceErrorRelay.accept(SwapValidationError.noBalance)
            return
        }

        balanceRelay.accept(Swap2Module.CoinWithBalance(coin: coin, balance: balance))

        if (_amountIn ?? 0) > balance {
            balanceErrorRelay.accept(SwapValidationError.insufficientBalance(availableBalance: balance.description)) //TODO: need to convert in VModel
        } else {
            balanceErrorRelay.accept(nil)
        }
    }

    private func sync() {

    }

}

extension Swap2Service {

    func tokensForSelection(type: TradeType) -> [Coin] {
        []
    }

    func onChange(type: TradeType, amount: String?) {
        switch type {
        case .exactIn:
            _amountIn = decimalParser.parseAnyDecimal(from: amount)
        case .exactOut:
            _amountOut = decimalParser.parseAnyDecimal(from: amount)
        }
        estimatedRelay.accept(type)

        sync()
    }

    func onSelect(type: TradeType, coin: Coin) {
        guard self.coin(for: type) != coin else {
            return
        }

        switch type {
        case .exactIn:
            coinInRelay.accept(coin)

            tryResetCoinOut(coin: coin)
        case .exactOut:
            coinOutRelay.accept(coin)
        }

        updateTradeData(type: type)
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

    var amountIn: Observable<Decimal?> {
        amountInRelay.asObservable()
    }

    var amountOut: Observable<Decimal?> {
        amountOutRelay.asObservable()
    }

    var balance: Observable<Swap2Module.CoinWithBalance?> {
        balanceRelay.asObservable()
    }

    var balanceError: Observable<Error?> {
        balanceErrorRelay.asObservable()
    }

    var allowance: Observable<DataStatus<Swap2Module.AllowanceItem>?> {
        allowanceState.asObservable()
    }

}
