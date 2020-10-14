import RxSwift
import RxRelay
import RxCocoa
import WalletConnect
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestViewModel {
    private let service: WalletConnectSendEthereumTransactionRequestService
    private let transaction: WalletConnectTransaction

    private let disposeBag = DisposeBag()

    let amountViewItem: WalletConnectRequestAmountViewItem
    let viewItems: [WalletConnectRequestViewItem]

    private let approveRelay = PublishRelay<Data>()

    init(service: WalletConnectSendEthereumTransactionRequestService, transaction: WalletConnectTransaction) {
        self.service = service
        self.transaction = transaction

        let value = Self.convert(amount: transaction.value, coin: service.ethereumCoin)

        let primaryAmountInfo: AmountInfo
        var secondaryAmountInfo: AmountInfo?

        let coinValue = CoinValue(coin: service.ethereumCoin, value: value)
        if let rate = service.ethereumRate {
            primaryAmountInfo = .currencyValue(currencyValue: CurrencyValue(currency: rate.currency, value: rate.value * value))
            secondaryAmountInfo = .coinValue(coinValue: coinValue)
        } else {
            primaryAmountInfo = .coinValue(coinValue: coinValue)
        }

        amountViewItem = WalletConnectRequestAmountViewItem(primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo)

        viewItems = [
            .from(value: transaction.from.eip55),
            .to(value: transaction.to.eip55)
        ]
    }

    private static func convert(amount: BigUInt, coin: Coin) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -coin.decimal, significand: significand)
    }

}

extension WalletConnectSendEthereumTransactionRequestViewModel: IWalletConnectRequestViewModel {

    var approveSignal: Signal<Data> {
        approveRelay.asSignal()
    }

    func approve() {
        approveRelay.accept(Data(repeating: 1, count: 4))
    }

}
