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

    private var coinInRelay: BehaviorRelay<Coin>
    private var coinOutRelay = BehaviorRelay<Coin?>(value: nil)

    private var amountIn: Decimal? = nil
    private var amountOut: Decimal? = nil

    private var balanceRelay = BehaviorRelay<Decimal?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var tradeDataState = BehaviorRelay<DataStatus<Swap2Module.TradeItem>?>(value: nil)
    private var allowanceState = BehaviorRelay<DataStatus<Decimal?>>(value: .completed(nil))

    private var actionType = BehaviorRelay<Swap2Module.ActionType>(value: .proceed)
    private var actionEnabled = BehaviorRelay<Bool>(value: false)

    init(uniswapRepository: UniswapRepository, allowanceRepository: AllowanceRepository, coin: Coin) {
        self.uniswapRepository = uniswapRepository
        self.allowanceRepository = allowanceRepository

        coinInRelay = BehaviorRelay(value: coin)
    }

    private func tryResetCoinOut(coin: Coin) {
        if coinOutRelay.value == coin {
            coinOutRelay.accept(nil)
        }
    }

    private func coin(for type: TradeType) -> Coin? {
        type == .exactIn ? coinInRelay.value : coinOutRelay.value
    }

}

extension Swap2Service {        // inputs

    func isValid(type: TradeType, amount: Decimal) -> Bool {
        let coinDecimal = coin(for: type)?.decimal ?? maxCoinDecimal

        let decimal = min(coinDecimal, maxCoinDecimal)

        let balance = type == .exactIn ? self.balanceRelay.value : nil
        let insufficientAmount = balance.map {
            amount > $0
        } ?? false

        return amount.decimalCount <= decimal && !insufficientAmount
    }

    func tokensForSelection(type: TradeType) -> [Coin] {
        []
    }

    func onChange(type: TradeType, amount: Decimal?) {
        switch type {
        case .exactIn:
            amountIn = amount
        case .exactOut:
            amountOut = amount
        }
    }

    func onSelect(type: TradeType, coin: Coin) {
        switch type {
        case .exactIn:
            coinInRelay.accept(coin)

            tryResetCoinOut(coin: coin)
        case .exactOut:
            coinOutRelay.accept(coin)
        }
    }

    var coinIn: Observable<Coin> {
        coinInRelay.asObservable()
    }

    var coinOut: Observable<Coin?> {
        coinOutRelay.asObservable()
    }

    var balance: Observable<Decimal?> {
        balanceRelay.asObservable()
    }

    var balanceError: Observable<Error?> {
        balanceErrorRelay.asObservable()
    }

}
