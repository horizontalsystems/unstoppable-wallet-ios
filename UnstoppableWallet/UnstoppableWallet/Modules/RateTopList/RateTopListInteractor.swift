import RxSwift
import XRatesKit
import CurrencyKit

class RateTopListInteractor {
    weak var delegate: IRateTopListInteractorDelegate?

    private let rateManager: IRateManager
    private let walletManager: IWalletManager

    private let disposeBag = DisposeBag()

    init(rateManager: IRateManager, walletManager: IWalletManager) {
        self.rateManager = rateManager
        self.walletManager = walletManager
    }

    private func update(coinMarkets: [CoinMarket]) {
        let items = coinMarkets.enumerated().map { index, coinMarket in
            RateTopListModule.TopMarketItem(
                    rank: index + 1,
                    coinCode: coinMarket.coin.code,
                    coinName: coinMarket.coin.title,
                    coinType: coinMarket.coin.type.flatMap { rateManager.convertXRateCoinTypeToCoinType(coinType: $0) },
                    marketInfo: coinMarket.marketInfo)
        }
        delegate?.didReceive(topMarkets: items)
    }

}

extension RateTopListInteractor: IRateTopListInteractor {

    var wallets: [Wallet] {
        walletManager.wallets
    }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func subscribeToMarketInfos(currencyCode: String) {
        rateManager.marketInfosObservable(currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.delegate?.didReceive(marketInfos: marketInfos)
                })
                .disposed(by: disposeBag)
    }

    func updateTopMarkets(currencyCode: String) {
        rateManager.topMarketsSingle(currencyCode: currencyCode, itemCount: 100)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] infos in
                    self?.update(coinMarkets: infos)
                })
                .disposed(by: disposeBag)
    }

}
