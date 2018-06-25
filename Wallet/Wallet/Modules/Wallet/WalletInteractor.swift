import Foundation
import RxSwift

class WalletInteractor {

    weak var delegate: IWalletInteractorDelegate?

    private let disposeBag = DisposeBag()
    private let databaseManager: DatabaseManager

    private var totalValues = [String: Double]()
    private var exchangeRates = [String: Double]()

    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }

}

extension WalletInteractor: IWalletInteractor {

    func notifyWalletBalances() {
        databaseManager.getUnspentOutputs()
                .subscribe(onNext: { [weak self] changeset in
                    self?.totalValues[Bitcoin().code] = changeset.array.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })
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

    func refresh() {
        let items: [WalletBalanceItem] = totalValues.compactMap { totalValueMap in
            let (code, totalValue) = totalValueMap

            if let rate = self.exchangeRates[code] {
                return WalletBalanceItem(coinValue: CoinValue(coin: Bitcoin(), value: totalValue), conversionRate: rate, conversionCurrency: DollarCurrency())
            }
            return nil
        }
        delegate?.didFetch(walletBalances: items)
    }

}
