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
        rateManager.topMarketInfos(currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] infos in
                    self?.delegate?.didReceive(topMarkets: infos)
                })
                .disposed(by: disposeBag)
    }

}
