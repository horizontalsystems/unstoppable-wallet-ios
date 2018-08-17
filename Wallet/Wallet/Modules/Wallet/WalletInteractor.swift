import Foundation
import RxSwift
import WalletKit

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()
    private let storage: IStorage

    private var totalValues = [String: Double]()
    private var exchangeRates = [String: Double]()

    init(storage: IStorage) {
        self.storage = storage
    }

}

extension WalletInteractor: IWalletInteractor {

    func notifyWalletBalances() {
//        databaseManager.getBitcoinUnspentOutputs()
//                .subscribe(onNext: { [weak self] changeset in
//                    self?.totalValues[Bitcoin()] = changeset.array.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })
//                    self?.refresh()
//                })
//                .disposed(by: disposeBag)
//
//        databaseManager.getBitcoinCashUnspentOutputs()
//                .subscribe(onNext: { [weak self] changeset in
//                    self?.totalValues[BitcoinCash()] = changeset.array.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })
//                    self?.refresh()
//                })
//                .disposed(by: disposeBag)

        storage.getBalances()
                .subscribe(onNext: { [weak self] changeset in
                    changeset.array.forEach { balance in
                        self?.totalValues[balance.coinCode] = balance.amount
                    }
                    self?.refresh()
                })
                .disposed(by: disposeBag)

        storage.getExchangeRates()
                .subscribe(onNext: { [weak self] changeset in
                    for rate in changeset.array {
                        self?.exchangeRates[rate.code] = rate.value
                    }
                    self?.refresh()
                })
                .disposed(by: disposeBag)

//        syncManager.syncSubject
//                .subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] status in
//                    self?.delegate?.didUpdate(syncStatus: status)
//                })
    }

    private func refresh() {
        let items: [WalletBalanceItem] = totalValues.compactMap { totalValueMap in
            let (coinCode, totalValue) = totalValueMap

            let coin = Factory.instance.coinManager.getCoin(byCode: coinCode)

            if let coin = coin, let rate = self.exchangeRates[coin.code] {
                return WalletBalanceItem(coinValue: CoinValue(coin: coin, value: totalValue), exchangeRate: rate, currency: DollarCurrency())
            }
            return nil
        }

        if !items.isEmpty {
            delegate?.didFetch(walletBalances: items)
        } else {
            //stab
            delegate?.didFetch(walletBalances: [])
        }
    }

}
