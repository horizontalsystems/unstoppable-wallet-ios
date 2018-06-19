import Foundation
import RxSwift

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()

    private var unspentOutputs: [UnspentOutput]
    private var exchangeRates: [String: Double]

    init(databaseManager: IDatabaseManager, unspentOutputUpdateSubject: PublishSubject<[UnspentOutput]>, exchangeRateUpdateSubject: PublishSubject<[String: Double]>) {
        unspentOutputs = databaseManager.getUnspentOutputs()
        exchangeRates = databaseManager.getExchangeRates()

        unspentOutputUpdateSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] unspentOutputs in
            self?.unspentOutputs = unspentOutputs
            self?.notifyWalletBalances()
        })

        exchangeRateUpdateSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] exchangeRates in
            self?.exchangeRates = exchangeRates
            self?.notifyWalletBalances()
        })
    }

}

extension WalletInteractor: IWalletInteractor {

    func notifyWalletBalances() {
        var totalValue: Double = 0

        for unspentOutput in unspentOutputs {
            totalValue += unspentOutput.value.toDouble
        }

        let bitcoin = Bitcoin()

        if let rate = exchangeRates[bitcoin.code] {
            let walletBalanceItem = WalletBalanceItem(coinValue: CoinValue(coin: bitcoin, value: totalValue), conversionRate: rate, conversionCurrency: DollarCurrency())
            delegate?.didFetch(walletBalances: [walletBalanceItem])
        }
    }

}
