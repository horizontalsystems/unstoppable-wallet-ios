import Foundation
import RxSwift

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()

    private var unspentOutputs: [UnspentOutput]
    private var exchangeRate: Double

    init(unspentOutputProvider: IUnspentOutputProvider, exchangeRateProvider: IExchangeRateProvider) {
        unspentOutputs = unspentOutputProvider.unspentOutputs
        exchangeRate = exchangeRateProvider.getExchangeRate(forCoin: Bitcoin())

        unspentOutputProvider.subject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] unspentOutputs in
            self?.unspentOutputs = unspentOutputs
            self?.notifyWalletBalances()
        })

        exchangeRateProvider.subject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] exchangeRates in
            if let rate = exchangeRates[Bitcoin().code] {
                self?.exchangeRate = rate
                self?.notifyWalletBalances()
            }
        })
    }

}

extension WalletInteractor: IWalletInteractor {

    func notifyWalletBalances() {
        var totalValue: Double = 0

        for unspentOutput in unspentOutputs {
            totalValue += unspentOutput.value.toDouble
        }

        let walletBalanceItem = WalletBalanceItem(coinValue: CoinValue(coin: Bitcoin(), value: totalValue), conversionRate: exchangeRate, conversionCurrency: DollarCurrency())

        delegate?.didFetch(walletBalances: [walletBalanceItem])
    }

}
