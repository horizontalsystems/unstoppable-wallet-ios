import RxSwift
import DeepDiff
import CurrencyKit
import CoinKit

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let dataSource: TransactionRecordDataSource
    private var loading = false

    private var wallets = [Wallet]()
    private var states = [TransactionWallet: AdapterState]()  // stores coin per blockchain

    weak var view: ITransactionsView?

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory,
         dataSource: TransactionRecordDataSource) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.dataSource = dataSource
    }

    var allTransactionWallets: [TransactionWallet] {
        let transactionWallets = wallets.map { transactionWallet(wallet: $0) }
        var mergedWallets = [TransactionWallet]()

        for wallet in transactionWallets {
            switch wallet.source.blockchain {
            case .bitcoin, .bitcoinCash, .litecoin, .dash, .zcash, .bep2: mergedWallets.append(wallet)
            case .ethereum, .binanceSmartChain:
                if !mergedWallets.contains(where: { wallet.source == $0.source }) {
                    mergedWallets.append(TransactionWallet(coin: nil, source: wallet.source))
                }
            }
        }

        return mergedWallets
    }

    private func transactionWallet(wallet: Wallet) -> TransactionWallet {
        let coinSettings = wallet.configuredCoin.settings
        let coin = wallet.coin

        switch coin.type {
        case .bitcoin:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .bitcoin, account: wallet.account, coinSettings: coinSettings))
        case .bitcoinCash:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .bitcoinCash, account: wallet.account, coinSettings: coinSettings))
        case .dash:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .dash, account: wallet.account, coinSettings: coinSettings))
        case .litecoin:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .litecoin, account: wallet.account, coinSettings: coinSettings))
        case .zcash:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .zcash, account: wallet.account, coinSettings: coinSettings))
        case .bep2(let symbol):
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .bep2(symbol: symbol), account: wallet.account, coinSettings: coinSettings))
        case .ethereum:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .ethereum, account: wallet.account, coinSettings: coinSettings))
        case .binanceSmartChain:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .binanceSmartChain, account: wallet.account, coinSettings: coinSettings))
        case .erc20:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .ethereum, account: wallet.account, coinSettings: coinSettings))
        case .bep20:
            return TransactionWallet(coin: coin, source: TransactionSource(blockchain: .binanceSmartChain, account: wallet.account, coinSettings: coinSettings))
        case .unsupported:
            fatalError("Unsupported coin may not have transactions to show")
        }
    }

    private func loadNext(initial: Bool = false) {
        guard !loading else {
            return
        }

        loading = true

        guard !dataSource.allShown else {
            if initial {
                //clear list on switch coins when data source has only one page
                view?.showNoTransactions()
            }

            loading = false
            return
        }

        interactor.fetchRecords(fetchDataList: dataSource.fetchDataList, initial: initial)
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.initialFetch()
    }

    func onFilterSelect(index: Int) {
        let selectedWallets: [TransactionWallet]

        if index == 0 {
            selectedWallets = allTransactionWallets
        } else {
            selectedWallets = [transactionWallet(wallet: wallets[index - 1])]
        }

        dataSource.set(wallets: selectedWallets)
        view?.set(status: factory.viewStatus(adapterStates: Array(states.values), transactionsCount: dataSource.items.count))

        loadNext(initial: true)
    }

    func onBottomReached() {
        DispatchQueue.main.async {
            self.loadNext()
        }
    }

    func onTransactionClick(item: TransactionViewItem) {
        router.openTransactionInfo(viewItem: item)
    }

    func willShow(item: TransactionViewItem) {
        if let mainValue = item.record.mainValue, item.mainAmountCurrencyString == nil {
            interactor.fetchRate(coin: mainValue.coin, date: item.date)
        }
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func onUpdate(wallets: [Wallet]) {
        self.wallets = wallets.sorted { wallet, wallet2 in wallet.coin.code < wallet2.coin.code }
        view?.show(filters: factory.filterItems(wallets: self.wallets))

        let transactionWallets = allTransactionWallets
        dataSource.handleUpdated(wallets: transactionWallets)
        interactor.fetchLastBlockHeights(wallets: transactionWallets)

        interactor.observe(wallets: transactionWallets)
    }

    func onUpdate(lastBlockInfos: [(TransactionWallet, LastBlockInfo?)]) {
        dataSource.handleUpdated(lastBlockInfos: lastBlockInfos)

        loadNext(initial: true)
    }

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: TransactionWallet) {
        if dataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet) {
            view?.show(transactions: dataSource.items, animated: false)
        }
    }

    func onUpdateBaseCurrency() {
        dataSource.clearRates()
        view?.show(transactions: dataSource.items, animated: true)
    }

    func onConnectionRestore() {
        view?.reloadTransactions()
    }

    func didUpdate(records: [TransactionRecord], wallet: TransactionWallet) {
        if let updatedViewItems = dataSource.handleUpdated(records: records, wallet: wallet) {
            view?.show(transactions: updatedViewItems, animated: true)

            view?.set(status: factory.viewStatus(adapterStates: Array(states.values), transactionsCount: dataSource.items.count))
        }
    }

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date) {
        if dataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coin: coin, date: date) {
            view?.show(transactions: dataSource.items, animated: false)
        }
    }

    func didFetch(recordsData: [TransactionWallet: [TransactionRecord]], initial: Bool) {
        dataSource.handleNext(recordsData: recordsData)

        // called after load next or when pool has not enough items
        if dataSource.increasePage() {
            view?.show(transactions: dataSource.items, animated: true)
        } else if initial {
            view?.showNoTransactions()
        }
        view?.set(status: factory.viewStatus(adapterStates: Array(states.values), transactionsCount: dataSource.items.count))

        loading = false
    }

    func onUpdate(states: [TransactionWallet: AdapterState]) {
        self.states = states

        view?.set(status: factory.viewStatus(adapterStates: Array(states.values), transactionsCount: dataSource.items.count))
    }

    func didUpdate(state: AdapterState, wallet: TransactionWallet) {
        states[wallet] = state

        view?.set(status: factory.viewStatus(adapterStates: Array(states.values), transactionsCount: dataSource.items.count))
    }

}
