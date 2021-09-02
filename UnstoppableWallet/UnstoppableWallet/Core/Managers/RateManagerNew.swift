import Foundation
import RxSwift
import CurrencyKit
import MarketKit

class RateManagerNew {
    private let disposeBag = DisposeBag()

    private let walletManager: WalletManagerNew
    private let feeCoinProvider: FeeCoinProvider
    private let appConfigProvider: IAppConfigProvider

    init(walletManager: WalletManagerNew, feeCoinProvider: FeeCoinProvider, appConfigProvider: IAppConfigProvider) {
        self.walletManager = walletManager
        self.feeCoinProvider = feeCoinProvider
        self.appConfigProvider = appConfigProvider
    }

}

extension RateManagerNew {

    func refresh(currencyCode: String) {
    }

    func latestRate(coinType: CoinType, currencyCode: String) -> LatestRate? {
        nil
    }

    func latestRateMap(coinTypes: [CoinType], currencyCode: String) -> [CoinType: LatestRate] {
        [:]
    }

    func latestRateObservable(coinType: CoinType, currencyCode: String) -> Observable<LatestRate> {
        Observable.empty()
    }

    func latestRatesObservable(coinTypes: [CoinType], currencyCode: String) -> Observable<[CoinType: LatestRate]> {
        Observable.empty()
    }

    func coinTypes(for category: String) -> [CoinType] {
        []
    }

}

extension RateManagerNew {

    public struct LatestRate {
        public let coinType: CoinType
        public let currencyCode: String
        public let rate: Decimal
        public let rateDiff24h: Decimal
        public let timestamp: TimeInterval

        private let expirationInterval: TimeInterval

        public var expired: Bool {
            Date().timeIntervalSince1970 - timestamp > expirationInterval
        }
    }

}
