import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit
import MarketKit

class SwapCoinCardViewModel {
    private let coinCardService: ISwapCoinCardService
    private let fiatService: FiatService
    private let disposeBag = DisposeBag()

    private var readOnlyRelay = BehaviorRelay<Bool>(value: false)
    private var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var balanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Bool>(value: false)
    private var tokenViewItemRelay = BehaviorRelay<TokenViewItem?>(value: nil)

    init(coinCardService: ISwapCoinCardService, fiatService: FiatService) {
        self.coinCardService = coinCardService
        self.fiatService = fiatService

        subscribe(disposeBag, coinCardService.readOnlyObservable) { [weak self] in self?.sync(readOnly: $0) }
        subscribe(disposeBag, coinCardService.isEstimatedObservable) { [weak self] _ in self?.syncEstimated() }
        subscribe(disposeBag, coinCardService.amountObservable) { [weak self] _ in self?.syncEstimated() }
        subscribe(disposeBag, coinCardService.platformCoinObservable) { [weak self] in self?.sync(platformCoin: $0) }
        subscribe(disposeBag, coinCardService.balanceObservable) { [weak self] in self?.sync(balance: $0) }
        subscribe(disposeBag, coinCardService.errorObservable) { [weak self] in self?.sync(error: $0) }

        sync(readOnly: coinCardService.readOnly)
        syncEstimated()
        sync(platformCoin: coinCardService.platformCoin)
        sync(balance: coinCardService.balance)
    }

    private func sync(readOnly: Bool) {
        readOnlyRelay.accept(readOnly)
    }

    private func syncEstimated() {
        fiatService.coinAmountLocked = coinCardService.isEstimated
        isEstimatedRelay.accept(coinCardService.isEstimated && coinCardService.amount != 0)
    }

    private func sync(platformCoin: PlatformCoin?) {
        tokenViewItemRelay.accept(platformCoin.map { TokenViewItem(title: $0.coin.code, iconUrlString: $0.coin.imageUrl) })
    }

    private func sync(balance: Decimal?) {
        guard let platformCoin = coinCardService.platformCoin else {
            balanceRelay.accept(nil)
            return
        }

        guard let balance = balance else {
            balanceRelay.accept("n/a".localized)
            return
        }

        let coinValue = CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: balance)
        balanceRelay.accept(ValueFormatter.instance.format(coinValueNew: coinValue))
    }

    private func sync(error: Error?) {
        balanceErrorRelay.accept(error != nil)
    }

}

extension SwapCoinCardViewModel {

    var dex: SwapModule.Dex {
        coinCardService.dex
    }

    var readOnlyDriver: Driver<Bool> {
        readOnlyRelay.asDriver()
    }

    var isEstimatedDriver: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

    var balanceDriver: Driver<String?> {
        balanceRelay.asDriver()
    }

    var balanceErrorDriver: Driver<Bool> {
        balanceErrorRelay.asDriver()
    }

    var tokenViewItemDriver: Driver<TokenViewItem?> {
        tokenViewItemRelay.asDriver()
    }

    func onSelect(platformCoin: PlatformCoin) {
        coinCardService.onChange(platformCoin: platformCoin)
    }

}

extension SwapCoinCardViewModel {

    struct TokenViewItem {
        let title: String
        let iconUrlString: String
    }

}
