import Combine
import Foundation
import MarketKit

protocol IWalletCoinPriceServiceDelegate: AnyObject {
    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]?)
}

class WalletCoinPriceService {
    weak var delegate: IWalletCoinPriceServiceDelegate?

    private let currencyManager = Core.shared.currencyManager
    private let priceChangeModeManager = Core.shared.priceChangeModeManager
    private let marketKit = Core.shared.marketKit
    private var cancellables = Set<AnyCancellable>()
    private var coinPriceCancellables = Set<AnyCancellable>()

    private(set) var currency: Currency
    private var coinUids = Set<String>()
    private var feeCoinUids = Set<String>()
    private var conversionCoinUids = Set<String>()

    init() {
        currency = currencyManager.baseCurrency

        currencyManager.$baseCurrency
            .sink { [weak self] currency in
                self?.onUpdate(baseCurrency: currency)
            }
            .store(in: &cancellables)

        priceChangeModeManager.$priceChangeMode
            .sink { [weak self] _ in
                self?.delegate?.didUpdate(itemsMap: nil)
            }
            .store(in: &cancellables)
    }

    private func onUpdate(baseCurrency: Currency) {
        currency = baseCurrency
        subscribeToCoinPrices()
        delegate?.didUpdate(itemsMap: nil)
    }

    private func subscribeToCoinPrices() {
        coinPriceCancellables = Set()

        if !coinUids.isEmpty {
            marketKit.coinPriceMapPublisher(coinUids: Array(coinUids), currencyCode: currencyManager.baseCurrency.code)
                .sink { [weak self] in
                    self?.onUpdate(coinPriceMap: $0)
                }
                .store(in: &coinPriceCancellables)
        }

        if !feeCoinUids.isEmpty {
            marketKit.coinPriceMapPublisher(coinUids: Array(feeCoinUids), currencyCode: currencyManager.baseCurrency.code)
                .sink { _ in }
                .store(in: &coinPriceCancellables)
        }

        if !conversionCoinUids.isEmpty {
            marketKit.coinPriceMapPublisher(coinUids: Array(conversionCoinUids), currencyCode: currencyManager.baseCurrency.code)
                .sink { _ in }
                .store(in: &coinPriceCancellables)
        }
    }

    private func onUpdate(coinPriceMap: [String: CoinPrice]) {
        let itemsMap = coinPriceMap.mapValues { item(coinPrice: $0) }
        delegate?.didUpdate(itemsMap: itemsMap)
    }

    private func item(coinPrice: CoinPrice) -> Item {
        let currency = currencyManager.baseCurrency

        let diff: Decimal?
        switch priceChangeModeManager.priceChangeMode {
        case .hour24:
            diff = coinPrice.diff24h
        case .day1:
            diff = coinPrice.diff1d
        }

        return Item(
            price: CurrencyValue(currency: currency, value: coinPrice.value),
            diff: diff,
            expired: coinPrice.expired
        )
    }
}

extension WalletCoinPriceService {
    func set(coinUids: Set<String>, feeCoinUids: Set<String> = Set(), conversionCoinUids: Set<String> = Set()) {
        if self.coinUids == coinUids, self.feeCoinUids == feeCoinUids, self.conversionCoinUids == conversionCoinUids {
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
    struct Item: Equatable {
        let price: CurrencyValue
        let diff: Decimal?
        let expired: Bool
    }
}
