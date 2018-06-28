import Foundation
import RxSwift

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()
    private let databaseManager: IDatabaseManager

    private var totalValues = [Coin: Double]()
    private var exchangeRates = [String: Double]()

    init(databaseManager: IDatabaseManager) {
        self.databaseManager = databaseManager
    }

}

extension WalletInteractor: IWalletInteractor {

    func notifyWalletBalances() {
        databaseManager.getBitcoinUnspentOutputs()
                .subscribe(onNext: { [weak self] changeset in
                    self?.totalValues[Bitcoin()] = changeset.array.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })
                    self?.refresh()
                })
                .disposed(by: disposeBag)

        databaseManager.getBitcoinCashUnspentOutputs()
                .subscribe(onNext: { [weak self] changeset in
                    self?.totalValues[BitcoinCash()] = changeset.array.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })
                    self?.refresh()
                })
                .disposed(by: disposeBag)

        databaseManager.getExchangeRates()
                .subscribe(onNext: { [weak self] changeset in
                    for rate in changeset.array {
                        self?.exchangeRates[rate.code] = rate.value
                    }
                    self?.refresh()
                })
                .disposed(by: disposeBag)
    }

    private func refresh() {
        let items: [WalletBalanceItem] = totalValues.compactMap { totalValueMap in
            let (coin, totalValue) = totalValueMap

            if let rate = self.exchangeRates[coin.code] {
                return WalletBalanceItem(coinValue: CoinValue(coin: coin, value: totalValue), exchangeRate: rate, currency: DollarCurrency())
            }
            return nil
        }

        if !items.isEmpty {
            delegate?.didFetch(walletBalances: items)
        }
    }

}
