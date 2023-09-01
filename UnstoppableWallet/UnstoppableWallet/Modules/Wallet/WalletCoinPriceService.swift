import Foundation
import Combine
import CurrencyKit
import MarketKit

protocol IWalletCoinPriceServiceDelegate: AnyObject {
    func didUpdateBaseCurrency()
    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item])
}

class WalletCoinPriceService {
    weak var delegate: IWalletCoinPriceServiceDelegate?

    private let tag: String
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit
    private var cancellables = Set<AnyCancellable>()
    private var coinPriceCancellables = Set<AnyCancellable>()

    private(set) var currency: Currency
    private var coinUids = Set<String>()
    private var feeCoinUids = Set<String>()
    private var conversionCoinUids = Set<String>()

    init(tag: String, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.tag = tag
        self.currencyKit = currencyKit
        self.marketKit = marketKit

        currency = currencyKit.baseCurrency

        currencyKit.baseCurrencyUpdatedPublisher
                .sink { [weak self] currency in
                    self?.onUpdate(baseCurrency: currency)
                }
                .store(in: &cancellables)
    }

    private func onUpdate(baseCurrency: Currency) {
        currency = baseCurrency
        subscribeToCoinPrices()
        delegate?.didUpdateBaseCurrency()
    }

    private func subscribeToCoinPrices() {
        coinPriceCancellables = Set()

        if !coinUids.isEmpty {
            marketKit.coinPriceMapPublisher(tag: tag, coinUids: Array(coinUids), currencyCode: currencyKit.baseCurrency.code)
                    .sink { [weak self] in
                        self?.onUpdate(coinPriceMap: $0)
                    }
                    .store(in: &coinPriceCancellables)
        }

        if !feeCoinUids.isEmpty {
            marketKit.coinPriceMapPublisher(tag: "fee:\(tag)", coinUids: Array(feeCoinUids), currencyCode: currencyKit.baseCurrency.code)
                    .sink { _ in }
                    .store(in: &coinPriceCancellables)
        }

        if !conversionCoinUids.isEmpty {
            marketKit.coinPriceMapPublisher(tag: "conversion:\(tag)", coinUids: Array(conversionCoinUids), currencyCode: currencyKit.baseCurrency.code)
                    .sink { _ in }
                    .store(in: &coinPriceCancellables)
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

    func set(coinUids: Set<String>, feeCoinUids: Set<String> = Set(), conversionCoinUids: Set<String> = Set()) {
        if self.coinUids == coinUids && self.feeCoinUids == feeCoinUids && self.conversionCoinUids == conversionCoinUids {
            return
        }

        self.coinUids = coinUids
        self.feeCoinUids = feeCoinUids
        self.conversionCoinUids = conversionCoinUids

        subscribeToCoinPrices()
    }

    func itemMap(coinUids: [String]) -> [String: Item] {
        marketKit.coinPriceMap(coinUids: coinUids, currencyCode: currency.code).mapValues {
            item(coinPrice: $0)
        }
    }

    func item(coinUid: String) -> Item? {
        marketKit.coinPrice(coinUid: coinUid, currencyCode: currency.code).map { item(coinPrice: $0) }
    }

    func refresh() {
        marketKit.refreshCoinPrices(currencyCode: currency.code)
    }

}

extension WalletCoinPriceService {

    struct Item {
        let price: CurrencyValue
        let diff: Decimal?
        let expired: Bool
    }

}
