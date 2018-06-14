import Foundation
import RxSwift

class WalletInteractor {
    let disposeBag = DisposeBag()

    weak var delegate: IWalletInteractorDelegate?

    let unspentOutputProvider: UnspentOutputProviderProtocol

    init(unspentOutputProvider: UnspentOutputProviderProtocol) {
        self.unspentOutputProvider = unspentOutputProvider


    }

}

extension WalletInteractor: IWalletInteractor {

    func fetchWalletBalances() {
        unspentOutputProvider.fetchUnspentOutputs()
    }

}

extension WalletInteractor: UnspentOutputProviderDelegate {

    func didFetch(unspentOutputs: [UnspentOutput]) {
        var totalValue: Int64 = 0

        for unspentOutput in unspentOutputs {
            totalValue += unspentOutput.value
        }

        let bitcoinWallet = WalletBalance(coinValue: CoinValue(coin: Bitcoin(), value: totalValue.toDouble), conversionRate: 7240.64, conversionCurrency: DollarCurrency())

        delegate?.didFetch(walletBalances: [bitcoinWallet])
    }

}
