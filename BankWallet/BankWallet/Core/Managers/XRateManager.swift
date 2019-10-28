import RxSwift
import XRatesKit

class XRateManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager

    let kit: XRatesKit

    init(walletManager: IWalletManager, currencyManager: ICurrencyManager) {
        self.walletManager = walletManager
        self.currencyManager = currencyManager

        kit = XRatesKit.instance(currencyCode: currencyManager.baseCurrency.code, minLogLevel: .verbose)

        walletManager.walletsUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.onWalletsUpdated()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.onBaseCurrencyUpdated()
                })
                .disposed(by: disposeBag)
    }

    private func onWalletsUpdated() {
        kit.set(coinCodes: walletManager.wallets.map { $0.coin.code })
    }

    private func onBaseCurrencyUpdated() {
        kit.set(currencyCode: currencyManager.baseCurrency.code)
    }

}

extension XRateManager: IXRateManager {
}
