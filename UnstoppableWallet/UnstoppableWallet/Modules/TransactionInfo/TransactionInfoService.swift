import CurrencyKit
import EthereumKit
import CoinKit
import RxSwift
import RxCocoa

class TransactionInfoService {
    private let disposeBag = DisposeBag()

    private let adapter: ITransactionsAdapter
    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit
    private let feeCoinProvider: IFeeCoinProvider
    private let appConfigProvider: IAppConfigProvider
    private let accountSettingManager: AccountSettingManager

    private let ratesRelay = PublishRelay<[Coin: CurrencyValue]>()

    init(adapter: ITransactionsAdapter, rateManager: IRateManager, currencyKit: CurrencyKit.Kit, feeCoinProvider: IFeeCoinProvider,
         appConfigProvider: IAppConfigProvider, accountSettingManager: AccountSettingManager) {
        self.adapter = adapter
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
        self.appConfigProvider = appConfigProvider
        self.accountSettingManager = accountSettingManager
    }
}

extension TransactionInfoService {

    var ratesSignal: Signal<[Coin: CurrencyValue]> {
        ratesRelay.asSignal()
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    var testMode: Bool {
        appConfigProvider.testMode
    }

    func ethereumNetworkType(account: Account) -> NetworkType {
        accountSettingManager.ethereumNetwork(account: account).networkType
    }

    func binanceSmartChainNetworkType(account: Account) -> NetworkType {
        accountSettingManager.binanceSmartChainNetwork(account: account).networkType
    }

    func fetchRates(coins: [Coin], timestamp: TimeInterval) {
        let baseCurrency = baseCurrency

        var singles: [Single<(coin: Coin, currencyValue: CurrencyValue)>] = coins.map { coin in
            rateManager
                    .historicalRate(coinType: coin.type, currencyCode: baseCurrency.code, timestamp: timestamp)
                    .map { (coin: coin, currencyValue: CurrencyValue(currency: baseCurrency, value: $0)) }
        }

        Single.zip(singles)
                .subscribe { [weak self] (rates: [(coin: Coin, currencyValue: CurrencyValue)]) in
                    var ratesMap = [Coin: CurrencyValue]()
                    for rate in rates {
                        ratesMap[rate.coin] = rate.currencyValue
                    }

                    self?.ratesRelay.accept(ratesMap)
                }
                .disposed(by: disposeBag)
    }

    func rawTransaction(hash: String) -> String? {
        adapter.rawTransaction(hash: hash)
    }

}
