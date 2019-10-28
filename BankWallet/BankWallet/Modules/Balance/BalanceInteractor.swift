import RxSwift
import XRatesKit

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private var disposeBag = DisposeBag()
    private var marketInfoDisposeBag = DisposeBag()
    private var chartsDisposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let currencyManager: ICurrencyManager
    private let localStorage: ILocalStorage
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let rateManager: IXRateManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, currencyManager: ICurrencyManager, localStorage: ILocalStorage, predefinedAccountTypeManager: IPredefinedAccountTypeManager, rateManager: IXRateManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager
        self.localStorage = localStorage
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.rateManager = rateManager
    }

    private func onUpdateWallets() {
        delegate?.didUpdate(wallets: walletManager.wallets)
    }

    private func onUpdateCurrency() {
        delegate?.didUpdate(currency: currencyManager.baseCurrency)
    }

}

extension BalanceInteractor: IBalanceInteractor {

    var wallets: [Wallet] {
        walletManager.wallets
    }

    var baseCurrency: Currency {
        currencyManager.baseCurrency
    }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func chartInfo(coinCode: CoinCode, currencyCode: String) -> ChartInfo? {
        rateManager.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: .day)
    }

    func balance(wallet: Wallet) -> Decimal? {
        adapterManager.balanceAdapter(for: wallet)?.balance
    }

    func state(wallet: Wallet) -> AdapterState? {
        adapterManager.balanceAdapter(for: wallet)?.state
    }

    func subscribeToWallets() {
        walletManager.walletsUpdatedSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateWallets()
                })
                .disposed(by: disposeBag)

        adapterManager.adaptersReadySignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateWallets()
                })
                .disposed(by: disposeBag)
    }

    func subscribeToBaseCurrency() {
        currencyManager.baseCurrencyUpdatedSignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCurrency()
                })
                .disposed(by: disposeBag)
    }

    func subscribeToAdapters(wallets: [Wallet]) {
        adaptersDisposeBag = DisposeBag()

        for wallet in wallets {
            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                continue
            }

            adapter.balanceUpdatedObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(balance: adapter.balance, wallet: wallet)
                    })
                    .disposed(by: adaptersDisposeBag)

            adapter.stateUpdatedObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(state: adapter.state, wallet: wallet)
                    })
                    .disposed(by: adaptersDisposeBag)
        }
    }

    func subscribeToMarketInfo(currencyCode: String) {
        marketInfoDisposeBag = DisposeBag()

        rateManager.marketInfosObservable(currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.delegate?.didUpdate(marketInfos: marketInfos)
                })
                .disposed(by: marketInfoDisposeBag)
    }

    func subscribeToChartInfo(coinCodes: [CoinCode], currencyCode: String) {
        chartsDisposeBag = DisposeBag()

        for coinCode in coinCodes {
            rateManager.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: .day)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] chartInfo in
                        self?.delegate?.didUpdate(chartInfo: chartInfo, coinCode: coinCode)
                    })
                    .disposed(by: chartsDisposeBag)
        }
    }

    func unsubscribeFromChartInfo() {
        chartsDisposeBag = DisposeBag()
    }

    var sortType: BalanceSortType {
        localStorage.balanceSortType ?? .name
    }

    func refresh() {
        adapterManager.refresh()
        rateManager.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.delegate?.didRefresh()
        }
    }

    func predefinedAccountType(wallet: Wallet) -> IPredefinedAccountType? {
        predefinedAccountTypeManager.predefinedAccountType(accountType: wallet.account.type)
    }

}
