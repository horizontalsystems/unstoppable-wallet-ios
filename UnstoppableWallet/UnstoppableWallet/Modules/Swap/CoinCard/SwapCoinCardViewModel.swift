import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit
import CoinKit

class SwapCoinCardViewModel {
    private let coinCardService: ISwapCoinCardService
    private let fiatService: FiatService
    private let disposeBag = DisposeBag()

    private var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var balanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Bool>(value: false)
    private var tokenCodeRelay = BehaviorRelay<String?>(value: nil)

    init(coinCardService: ISwapCoinCardService, fiatService: FiatService) {
        self.coinCardService = coinCardService
        self.fiatService = fiatService

        subscribe(disposeBag, coinCardService.isEstimatedObservable) { [weak self] in self?.sync(estimated: $0) }
        subscribe(disposeBag, coinCardService.coinObservable) { [weak self] in self?.sync(coin: $0) }
        subscribe(disposeBag, coinCardService.balanceObservable) { [weak self] in self?.sync(balance: $0) }
        subscribe(disposeBag, coinCardService.errorObservable) { [weak self] in self?.sync(error: $0) }

        sync(estimated: coinCardService.isEstimated)
        sync(coin: coinCardService.coin)
        sync(balance: coinCardService.balance)
    }

    private func sync(estimated: Bool) {
        fiatService.coinAmountLocked = estimated
        isEstimatedRelay.accept(estimated)
    }

    private func sync(coin: Coin?) {
        tokenCodeRelay.accept(coin?.code)
    }

    private func sync(balance: Decimal?) {
        guard let coin = coinCardService.coin else {
            balanceRelay.accept(nil)
            return
        }

        guard let balance = balance else {
            balanceRelay.accept("n/a".localized)
            return
        }

        let coinValue = CoinValue(coin: coin, value: balance)
        balanceRelay.accept(ValueFormatter.instance.format(coinValue: coinValue))
    }

    private func sync(error: Error?) {
        balanceErrorRelay.accept(error != nil)
    }

}

extension SwapCoinCardViewModel {

    var dex: SwapModule.Dex {
        coinCardService.dex
    }

    var isEstimated: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

    var balanceDriver: Driver<String?> {
        balanceRelay.asDriver()
    }

    var balanceErrorDriver: Driver<Bool> {
        balanceErrorRelay.asDriver()
    }

    var tokenCodeDriver: Driver<String?> {
        tokenCodeRelay.asDriver()
    }

    func onSelect(coin: Coin) {
        coinCardService.onChange(coin: coin)
    }

}
