import CurrencyKit

class TransactionInfoPresenter {
    weak var view: ITransactionInfoView?

    private let interactor: ITransactionInfoInteractor
    private let router: ITransactionInfoRouter

    private let transaction: TransactionRecord
    private let wallet: Wallet

    init?(transactionHash: String, wallet: Wallet, interactor: ITransactionInfoInteractor, router: ITransactionInfoRouter) {
        guard let transaction = interactor.transaction(hash: transactionHash) else {
            return nil
        }

        self.transaction = transaction
        self.wallet = wallet
        self.interactor = interactor
        self.router = router
    }

    private func showFromAddress(for type: CoinType) -> Bool {
        !(type == .bitcoin || type == .litecoin || type == .bitcoinCash || type == .dash)
    }

}

extension TransactionInfoPresenter: ITransactionInfoViewDelegate {

    func onLoad() {
        let coin = wallet.coin
        let lastBlockInfo = interactor.lastBlockInfo

        let status = transaction.status(lastBlockHeight: lastBlockInfo?.height, threshold: interactor.confirmationThreshold)
        let lockState = transaction.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)

        let rate: CurrencyValue? = nil // non zero
//        let rate: CurrencyValue? = CurrencyValue(currency: App.shared.currencyKit.baseCurrency, value: 9123)

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

        viewItems.append(.id(value: transaction.transactionHash))
//        viewItems.append(.rawTransaction)

        viewItems.append(.status(status: status, incoming: transaction.type == .incoming))

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

    func onTapVerify() {
        router.showFullInfo(transactionHash: transaction.transactionHash, wallet: wallet)
    }

    func onTapLockInfo() {
        router.showLockInfo()
    }

    func onTapDoubleSpendInfo() {
        router.showDoubleSpendInfo(txHash: transaction.transactionHash, conflictingTxHash: transaction.conflictingHash)
    }

    func onTapCopyRawTransaction() {
        guard let rawTransaction = interactor.rawTransaction(hash: transaction.transactionHash) else {
            return
        }

        interactor.copy(value: rawTransaction)
        view?.showCopied()
    }

}
