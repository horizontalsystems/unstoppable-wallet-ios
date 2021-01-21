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
    private let sortTypeManager: ISortTypeManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let rateManager: IRateManager
    private let rateAppManager: IRateAppManager
    private let accountManager: IAccountManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, currencyKit: ICurrencyKit, localStorage: ILocalStorage, sortTypeManager: ISortTypeManager, predefinedAccountTypeManager: IPredefinedAccountTypeManager, rateManager: IRateManager, rateAppManager: IRateAppManager, accountManager: IAccountManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyKit = currencyKit
        self.localStorage = localStorage
        self.sortTypeManager = sortTypeManager
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.rateManager = rateManager
        self.rateAppManager = rateAppManager
        self.accountManager = accountManager

        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] baseCurrency in
                    self?.onUpdate(baseCurrency: baseCurrency)
                })
                .disposed(by: disposeBag)

        sortTypeManager.sortTypeObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] sortType in
                    self?.delegate?.didUpdate(sortType: sortType)
                })
                .disposed(by: disposeBag)

        accountManager.lostAccountsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isAccountsLost in
                    if isAccountsLost {
                        self?.delegate?.onLostAccounts()
                    }
                })
                .disposed(by: disposeBag)
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
        adapterManager.balanceAdapter(for: wallet)?.balanceState
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

            adapter.balanceStateUpdatedObservable
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] in
                        self?.delegate?.didUpdate(state: adapter.balanceState, wallet: wallet)
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

    var sortType: SortType {
        sortTypeManager.sortType
    }

    var balanceHidden: Bool {
        get {
            localStorage.balanceHidden
        }
        set {
            localStorage.balanceHidden = newValue
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

    func notifyAppear() {
        rateAppManager.onBalancePageAppear()
    }

    func notifyDisappear() {
        rateAppManager.onBalancePageDisappear()
    }

}
