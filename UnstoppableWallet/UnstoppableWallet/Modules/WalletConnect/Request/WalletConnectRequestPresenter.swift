import RxSwift
import RxRelay
import RxCocoa
import WalletConnect
import CurrencyKit

class WalletConnectRequestPresenter {
    private let service: WalletConnectService
    private let requestId: Int

    private let disposeBag = DisposeBag()

    private let amountViewItemRelay = BehaviorRelay<AmountViewItem?>(value: nil)
    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private let finishRelay = PublishRelay<Void>()

    init(service: WalletConnectService, requestId: Int) {
        self.service = service
        self.requestId = requestId

        if let request = service.request(id: requestId) {
            switch request.type {
            case .sendEthereumTransaction(let transaction):
                sync(transaction: transaction)
            case .signEthereumTransaction(let transaction):
                sync(transaction: transaction)
            }

        }
    }

    private func sync(transaction: WCEthereumTransaction) {
        guard let ethereumCoin = service.ethereumCoin else {
            return
        }

        let amountViewItem = AmountViewItem(
                primaryAmountInfo: .coinValue(coinValue: CoinValue(coin: ethereumCoin, value: 0.25)),
                secondaryAmountInfo: nil
        )
        amountViewItemRelay.accept(amountViewItem)

        var viewItems: [ViewItem] = [
            .from(value: transaction.from)
        ]

        if let to = transaction.to {
            viewItems.append(.to(value: to))
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension WalletConnectRequestPresenter {

    var amountViewItemDriver: Driver<AmountViewItem?> {
        amountViewItemRelay.asDriver()
    }

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func approve() {
        finishRelay.accept(())
    }

    func reject() {
        service.rejectRequest(id: requestId)
        finishRelay.accept(())
    }

}

extension WalletConnectRequestPresenter {

    struct AmountViewItem {
        let primaryAmountInfo: AmountInfo
        let secondaryAmountInfo: AmountInfo?
    }

    enum ViewItem {
        case from(value: String)
        case to(value: String)
        case fee(coinValue: CoinValue, currencyValue: CurrencyValue?)
    }

}
