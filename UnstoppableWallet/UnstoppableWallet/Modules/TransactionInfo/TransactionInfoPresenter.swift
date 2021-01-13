import CurrencyKit

class TransactionInfoPresenter {
    weak var view: ITransactionInfoView?

    private let interactor: ITransactionInfoInteractor
    private let router: ITransactionInfoRouter

    private let transaction: TransactionRecord
    private let wallet: Wallet

    private let explorerData: TransactionInfoModule.ExplorerData

    init(transaction: TransactionRecord, wallet: Wallet, interactor: ITransactionInfoInteractor, router: ITransactionInfoRouter) {
        self.transaction = transaction
        self.wallet = wallet
        self.interactor = interactor
        self.router = router

        let testMode = interactor.testMode
        let hash = transaction.transactionHash

        switch wallet.coin.type {
        case .bitcoin:
            explorerData = .init(title: "btc.com", url: testMode ? nil : "https://btc.com/" + hash)
        case .bitcoinCash:
            explorerData = .init(title: "btc.com", url: testMode ? nil : "https://bch.btc.com/" + hash)
        case .litecoin:
            explorerData = .init(title: "blockchair.com", url: testMode ? nil : "https://blockchair.com/litecoin/transaction/" + hash)
        case .dash:
            explorerData = .init(title: "dash.org", url: testMode ? nil : "https://insight.dash.org/insight/tx/" + hash)
        case .ethereum, .erc20:
            explorerData = .init(title: "etherscan.io", url: testMode ? "https://ropsten.etherscan.io/tx/" + hash : "https://etherscan.io/tx/" + hash)
        case .binance:
            explorerData = .init(title: "binance.org", url: testMode ? "https://testnet-explorer.binance.org/tx/" + hash : "https://explorer.binance.org/tx/" + hash)
        case .zcash:
            explorerData = .init(title: "zcha.in", url: testMode ? nil : "https://explorer.zcha.in/transactions/" + hash)
        }
    }

    private func showFromAddress(for type: CoinType) -> Bool {
        !(type == .bitcoin || type == .litecoin || type == .bitcoinCash || type == .dash)
    }

    private var rateCurrencyValue: CurrencyValue? {
        let currency = interactor.baseCurrency

        guard let rate = interactor.rate(coinCode: wallet.coin.code, currencyCode: currency.code, timestamp: transaction.date.timeIntervalSince1970) else {
            return nil
        }

        return CurrencyValue(currency: currency, value: rate)
    }

}

extension TransactionInfoPresenter: ITransactionInfoViewDelegate {

    func onLoad() {
        let coin = wallet.coin
        let lastBlockInfo = interactor.lastBlockInfo

        let status = transaction.status(lastBlockHeight: lastBlockInfo?.height)
        let lockState = transaction.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)

        let rate = rateCurrencyValue?.nonZero

        let primaryAmountInfo: AmountInfo
        var secondaryAmountInfo: AmountInfo?

        let coinValue = CoinValue(coin: coin, value: transaction.amount)
        if let rate = rate {
            primaryAmountInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * transaction.amount))
            secondaryAmountInfo = .coinValue(coinValue: coinValue)
        } else {
            primaryAmountInfo = .coinValue(coinValue: coinValue)
        }

        view?.set(
                date: transaction.date,
                primaryAmountInfo: primaryAmountInfo,
                secondaryAmountInfo: secondaryAmountInfo,
                type: transaction.type,
                lockState: lockState
        )

        var viewItems = [TransactionInfoModule.ViewItem]()

        viewItems.append(.status(status: status, incoming: transaction.type == .incoming))

        if let rate = rate {
            viewItems.append(.rate(currencyValue: rate, coinCode: coin.code))
        }

        if let fee = transaction.fee {
            let feeCoin = interactor.feeCoin(coin: coin) ?? coin

            viewItems.append(.fee(
                    coinValue: CoinValue(coin: feeCoin, value: fee),
                    currencyValue: rate.map { CurrencyValue(currency: $0.currency, value: $0.value * fee) }
            ))
        }

        if let from = transaction.from, showFromAddress(for: coin.type) {
            viewItems.append(.from(value: from))
        }

        if let to = transaction.to {
            viewItems.append(.to(value: to))
        }

        if transaction.type == .outgoing, let recipient = transaction.lockInfo?.originalAddress {
            viewItems.append(.recipient(value: recipient))
        }

        if transaction.showRawTransaction {
            viewItems.append(.rawTransaction)
        } else {
            viewItems.append(.id(value: transaction.transactionHash))
        }

        if let memo = transaction.memo, !memo.isEmpty {
            viewItems.append(.memo(text: memo))
        }

        if transaction.conflictingHash != nil {
            viewItems.append(.doubleSpend)
        }

        if let lockState = lockState {
            viewItems.append(.lockInfo(lockState: lockState))
        }

        if transaction.type == .sentToSelf {
            viewItems.append(.sentToSelf)
        }

        view?.set(viewItems: viewItems)

        view?.set(explorerTitle: explorerData.title, enabled: explorerData.url != nil)
    }

    func onTapFrom() {
        guard let value = transaction.from else {
            return
        }

        interactor.copy(value: value)
        view?.showCopied()
    }

    func onTapTo() {
        guard let value = transaction.to else {
            return
        }

        interactor.copy(value: value)
        view?.showCopied()
    }

    func onTapRecipient() {
        guard let value = transaction.lockInfo?.originalAddress else {
            return
        }

        interactor.copy(value: value)
        view?.showCopied()
    }

    func onTapTransactionId() {
        interactor.copy(value: transaction.transactionHash)
        view?.showCopied()
    }

    func onTapShareTransactionId() {
        router.showShare(value: transaction.transactionHash)
    }

    func onTapShareRawTransaction() {
        guard let rawTransaction = interactor.rawTransaction(hash: transaction.transactionHash) else {
            return
        }

        router.showShare(value: rawTransaction)
    }

    func onTapVerify() {
        guard let url = explorerData.url else {
            return
        }

        router.open(url: url)
    }

    func onTapLockInfo() {
        router.showLockInfo()
    }

    func onTapDoubleSpendInfo() {
        guard let conflictingHash = transaction.conflictingHash else {
            return
        }

        router.showDoubleSpendInfo(txHash: transaction.transactionHash, conflictingTxHash: conflictingHash)
    }

}
