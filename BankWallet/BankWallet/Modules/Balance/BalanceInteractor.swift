import RxSwift
import XRatesKit
import CurrencyKit

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private var disposeBag = DisposeBag()
    private var marketInfoDisposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let currencyKit: ICurrencyKit
    private let localStorage: ILocalStorage
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let rateManager: IRateManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, currencyKit: ICurrencyKit, localStorage: ILocalStorage, predefinedAccountTypeManager: IPredefinedAccountTypeManager, rateManager: IRateManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyKit = currencyKit
        self.localStorage = localStorage
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.rateManager = rateManager
    }

    private func onUpdate(wallets: [Wallet]) {
        delegate?.didUpdate(wallets: wallets)
    }

    private func onAdaptersReady() {
        delegate?.didPrepareAdapters()
    }

    private func onUpdate(baseCurrency: Currency) {
        delegate?.didUpdate(currency: baseCurrency)
    }

}

extension BalanceInteractor: IBalanceInteractor {

    var wallets: [Wallet] {
        walletManager.wallets
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo? {
        rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func balance(wallet: Wallet) -> Decimal? {
        adapterManager.balanceAdapter(for: wallet)?.balance
    }

    func balanceLocked(wallet: Wallet) -> Decimal? {
        adapterManager.balanceAdapter(for: wallet)?.balanceLocked
    }

    func state(wallet: Wallet) -> AdapterState? {
        adapterManager.balanceAdapter(for: wallet)?.state
    }

    func subscribeToWallets() {
        walletManager.walletsUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                .subscribe(onNext: { [weak self] wallets in
                    self?.onUpdate(wallets: wallets)
                })
                .disposed(by: disposeBag)

        adapterManager.adaptersReadyObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] in
                    self?.onAdaptersReady()
                })
                .disposed(by: disposeBag)
    }

    func subscribeToBaseCurrency() {
        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] baseCurrency in
                    self?.onUpdate(baseCurrency: baseCurrency)
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
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(balance: adapter.balance, balanceLocked: adapter.balanceLocked, wallet: wallet)
                    })
                    .disposed(by: adaptersDisposeBag)

            adapter.stateUpdatedObservable
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(state: adapter.state, wallet: wallet)
                    })
                    .disposed(by: adaptersDisposeBag)
        }
    }

    func subscribeToMarketInfo(currencyCode: String) {
        marketInfoDisposeBag = DisposeBag()

        rateManager.marketInfosObservable(currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.delegate?.didUpdate(marketInfos: marketInfos)
                })
                .disposed(by: marketInfoDisposeBag)
    }

    var sortType: BalanceSortType? {
        get {
            localStorage.balanceSortType
        }
        set {
            localStorage.balanceSortType = newValue
        }
    }

    func refresh() {
        adapterManager.refresh()
        rateManager.refresh()

        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1) {
            self.delegate?.didRefresh()
        }
    }

    func predefinedAccountType(wallet: Wallet) -> PredefinedAccountType? {
        predefinedAccountTypeManager.predefinedAccountType(accountType: wallet.account.type)
    }

}
