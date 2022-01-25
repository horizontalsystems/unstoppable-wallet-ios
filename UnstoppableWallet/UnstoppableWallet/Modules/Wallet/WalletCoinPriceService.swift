import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

protocol IWalletRateServiceDelegate: AnyObject {
    func didUpdateBaseCurrency()
    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item])
}

class WalletCoinPriceService {
    weak var delegate: IWalletRateServiceDelegate?

    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit
    private let disposeBag = DisposeBag()
    private var coinPriceDisposeBag = DisposeBag()

    private(set) var currency: Currency
    private var coinUids = Set<String>()

    init(currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.currencyKit = currencyKit
        self.marketKit = marketKit

        currency = currencyKit.baseCurrency

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in
            self?.onUpdate(baseCurrency: baseCurrency)
        }
    }

    private func onUpdate(baseCurrency: Currency) {
        currency = baseCurrency
        subscribeToCoinPrices()
        delegate?.didUpdateBaseCurrency()
    }

    private func subscribeToCoinPrices() {
        coinPriceDisposeBag = DisposeBag()

        subscribe(coinPriceDisposeBag, marketKit.coinPriceMapObservable(coinUids: Array(coinUids), currencyCode: currencyKit.baseCurrency.code)) { [weak self] in
            self?.onUpdate(coinPriceMap: $0)
        }
    }

    private func onUpdate(coinPriceMap: [String: CoinPrice]) {
        let itemsMap = coinPriceMap.mapValues { item(coinPrice: $0) }
        delegate?.didUpdate(itemsMap: itemsMap)
    }

    private func item(coinPrice: CoinPrice) -> Item {
        let currency = currencyKit.baseCurrency

        return Item(
                price: CurrencyValue(currency: currency, value: coinPrice.value),
                diff: coinPrice.diff,
                expired: coinPrice.expired
        )
    }

}

extension WalletCoinPriceService {

    func set(coinUids: Set<String>) {
        guard self.coinUids != coinUids else {
            return
        }

        self.coinUids = coinUids
        subscribeToCoinPrices()
    }

    func itemMap(coinUids: [String]) -> [String: Item] {
        marketKit.coinPriceMap(coinUids: coinUids, currencyCode: currency.code).mapValues { item(coinPrice: $0) }
    }

    func refresh() {
        marketKit.refreshCoinPrices(currencyCode: currency.code)
    }

}

extension WalletCoinPriceService {

    struct Item {
        let price: CurrencyValue
        let diff: Decimal
        let expired: Bool
    }

}
