import RxSwift
import RxRelay
import RxCocoa
import WalletConnect
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestViewModel {
    private let service: WalletConnectSendEthereumTransactionRequestService
    private let request: WalletConnectSendEthereumTransactionRequest

    private let disposeBag = DisposeBag()

    private let amountViewItemRelay = BehaviorRelay<WalletConnectRequestAmountViewItem?>(value: nil)
    private let viewItemsRelay = BehaviorRelay<[WalletConnectRequestViewItem]>(value: [])

    private let approveRelay = PublishRelay<Any>()

    init(service: WalletConnectSendEthereumTransactionRequestService, request: WalletConnectSendEthereumTransactionRequest) {
        self.service = service
        self.request = request

        sync(transaction: request.transaction)
    }

    private func convert(amount: BigUInt) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -service.ethereumCoin.decimal, significand: significand)
    }

    private func sync(transaction: WalletConnectSendEthereumTransactionRequest.Transaction) {
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

        let amountViewItem = WalletConnectRequestAmountViewItem(primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo)
        amountViewItemRelay.accept(amountViewItem)

        let viewItems: [WalletConnectRequestViewItem] = [
            .from(value: transaction.from.eip55),
            .to(value: transaction.to.eip55)
        ]
        viewItemsRelay.accept(viewItems)
    }

}

extension WalletConnectSendEthereumTransactionRequestViewModel: IWalletConnectRequestViewModel {

    var requestId: Int {
        request.id
    }

    var amountViewItemDriver: Driver<WalletConnectRequestAmountViewItem?> {
        amountViewItemRelay.asDriver()
    }

    var viewItemsDriver: Driver<[WalletConnectRequestViewItem]> {
        viewItemsRelay.asDriver()
    }

    var approveSignal: Signal<Any> {
        approveRelay.asSignal()
    }

    func approve() {
        approveRelay.accept(Data(repeating: 1, count: 4))
    }

}
