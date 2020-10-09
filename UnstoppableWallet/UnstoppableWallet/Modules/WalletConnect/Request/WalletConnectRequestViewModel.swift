import RxSwift
import RxRelay
import RxCocoa
import WalletConnect
import CurrencyKit
import BigInt

class WalletConnectRequestViewModel {
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

    private func convert(amount: BigUInt) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -service.ethereumCoin.decimal, significand: significand)
    }

    private func sync(transaction: WalletConnectService.EthereumTransaction) {
        let value = convert(amount: transaction.value)

        let primaryAmountInfo: AmountInfo
        var secondaryAmountInfo: AmountInfo?

        let coinValue = CoinValue(coin: service.ethereumCoin, value: value)
        if let rate = service.ethereumRate {
            primaryAmountInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * value))
            secondaryAmountInfo = .coinValue(coinValue: coinValue)
        } else {
            primaryAmountInfo = .coinValue(coinValue: coinValue)
        }

        let amountViewItem = AmountViewItem(primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo)
        amountViewItemRelay.accept(amountViewItem)

        let viewItems: [ViewItem] = [
            .from(value: transaction.from.eip55),
            .to(value: transaction.to.eip55)
        ]
        viewItemsRelay.accept(viewItems)
    }

}

extension WalletConnectRequestViewModel {

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
        service.approveRequest(id: requestId)
        finishRelay.accept(())
    }

    func reject() {
        service.rejectRequest(id: requestId)
        finishRelay.accept(())
    }

}

extension WalletConnectRequestViewModel {

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
