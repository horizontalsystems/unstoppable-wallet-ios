import RxSwift
import RealmSwift

class TransactionsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let exchangeRateManager: IExchangeRateManager
    private let realmFactory: IRealmFactory

    init(walletManager: IWalletManager, exchangeRateManager: IExchangeRateManager, realmFactory: IRealmFactory) {
        self.walletManager = walletManager
        self.exchangeRateManager = exchangeRateManager
        self.realmFactory = realmFactory
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func realmResults(forCoin coin: Coin?) -> Results<TransactionRecord> {
        var results = realmFactory.realm.objects(TransactionRecord.self).sorted(byKeyPath: "timestamp", ascending: false)

        if let coin = coin {
            results = results.filter("coin = %@", coin)
        }

        return results
    }

    func retrieveFilters() {
        let coins = walletManager.wallets.map { $0.coin }
        delegate?.didRetrieve(filters: coins)
    }

}
