import RxSwift
import WalletKit

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var secondaryDisposeBag = DisposeBag()

    private let adapterManager: IAdapterManager
    private let exchangeRateManager: IExchangeRateManager

    init(adapterManager: IAdapterManager, exchangeRateManager: IExchangeRateManager) {
        self.adapterManager = adapterManager
        self.exchangeRateManager = exchangeRateManager
    }

}

extension WalletInteractor: IWalletInteractor {

    func notifyWalletBalances() {
        adapterManager.subject
                .subscribe(onNext: { [weak self] in
                    self?.secondaryDisposeBag = DisposeBag()
                    self?.initialFetchAndSubscribe()
                })
                .disposed(by: disposeBag)

        initialFetchAndSubscribe()
    }

    private func initialFetchAndSubscribe() {
        var coinValues = [String: CoinValue]()
        var progressSubjects = [String: BehaviorSubject<Double>]()

        for adapter in adapterManager.adapters {
            coinValues[adapter.id] = CoinValue(coin: adapter.coin, value: adapter.balance)
            progressSubjects[adapter.id] = adapter.progressSubject
        }

        let rates = exchangeRateManager.exchangeRates

        delegate?.didInitialFetch(coinValues: coinValues, rates: rates, progressSubjects: progressSubjects, currency: DollarCurrency())

        for adapter in adapterManager.adapters {
            adapter.balanceSubject
                    .subscribe(onNext: { [weak self] value in
                        self?.delegate?.didUpdate(coinValue: CoinValue(coin: adapter.coin, value: value), adapterId: adapter.id)
                    })
                    .disposed(by: secondaryDisposeBag)
        }

        exchangeRateManager.subject
                .subscribe(onNext: { [weak self] rates in
                    self?.delegate?.didUpdate(rates: rates)
                })
                .disposed(by: secondaryDisposeBag)
    }

}
