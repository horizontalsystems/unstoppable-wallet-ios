import CurrencyKit

class TransactionInfoPresenter {
    weak var view: ITransactionInfoView?

    private let interactor: ITransactionInfoInteractor
    private let router: ITransactionInfoRouter

    private let viewItem: TransactionViewItem

    init(viewItem: TransactionViewItem, interactor: ITransactionInfoInteractor, router: ITransactionInfoRouter) {
        self.viewItem = viewItem
        self.interactor = interactor
        self.router = router
    }

}

extension TransactionInfoPresenter: ITransactionInfoViewDelegate {

    func onLoad() {
        let primaryAmountInfo: AmountInfo
        var secondaryAmountInfo: AmountInfo?

        if let currencyValue = viewItem.currencyValue?.nonZero {
            primaryAmountInfo = .currencyValue(currencyValue: currencyValue)
            secondaryAmountInfo = .coinValue(coinValue: viewItem.coinValue)
        } else {
            primaryAmountInfo = .coinValue(coinValue: viewItem.coinValue)
        }

        view?.set(
                date: viewItem.date,
                primaryAmountInfo: primaryAmountInfo,
                secondaryAmountInfo: secondaryAmountInfo,
                type: viewItem.type,
                locked: viewItem.lockInfo.map { _ in !viewItem.unlocked }
        )

        var viewItems = [TransactionInfoModule.ViewItem]()

        if let rate = viewItem.rate?.nonZero {
            viewItems.append(.rate(currencyValue: rate, coinCode: viewItem.coinValue.coin.code))
        }

        if let feeCoinValue = viewItem.feeCoinValue {
            viewItems.append(.fee(
                    coinValue: feeCoinValue,
                    currencyValue: viewItem.rate?.nonZero.map { CurrencyValue(currency: $0.currency, value: $0.value * feeCoinValue.value) }
            ))
        }

        viewItems.append(.status(status: viewItem.status, incoming: viewItem.type == .incoming))

        if let from = viewItem.from {
            viewItems.append(.from(value: from))
        }

        if let to = viewItem.to {
            viewItems.append(.to(value: to))
        }

        if viewItem.type == .outgoing, let recipient = viewItem.lockInfo?.originalAddress {
            viewItems.append(.recipient(value: recipient))
        }

        viewItems.append(.id(value: viewItem.transactionHash))

        if viewItem.conflictingTxHash != nil {
            viewItems.append(.doubleSpend)
        }

        if let lockInfo = viewItem.lockInfo {
            viewItems.append(.lockInfo(lockedUntil: lockInfo.lockedUntil, unlocked: viewItem.unlocked))
        }

        if viewItem.type == .sentToSelf {
            viewItems.append(.sentToSelf)
        }

        view?.set(viewItems: viewItems)
    }

    func onTapFrom() {
        guard let value = viewItem.from else {
            return
        }

        interactor.copy(value: value)
        view?.showCopied()
    }

    func onTapTo() {
        guard let value = viewItem.to else {
            return
        }

        interactor.copy(value: value)
        view?.showCopied()
    }

    func onTapRecipient() {
        guard let value = viewItem.lockInfo?.originalAddress else {
            return
        }

        interactor.copy(value: value)
        view?.showCopied()
    }

    func onTapTransactionId() {
        interactor.copy(value: viewItem.transactionHash)
        view?.showCopied()
    }

    func onTapShareTransactionId() {
        router.showShare(value: viewItem.transactionHash)
    }

    func onTapVerify() {
        router.showFullInfo(transactionHash: viewItem.transactionHash, wallet: viewItem.wallet)
    }

    func onTapLockInfo() {
        router.showLockInfo()
    }

    func onTapDoubleSpendInfo() {
        router.showDoubleSpendInfo(txHash: viewItem.transactionHash, conflictingTxHash: viewItem.conflictingTxHash)
    }

}
