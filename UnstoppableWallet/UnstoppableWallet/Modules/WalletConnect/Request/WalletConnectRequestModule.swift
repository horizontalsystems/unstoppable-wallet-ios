import RxCocoa
import CurrencyKit

protocol IWalletConnectRequestViewModel {
    var requestId: Int { get }
    var amountViewItemDriver: Driver<WalletConnectRequestAmountViewItem?> { get }
    var viewItemsDriver: Driver<[WalletConnectRequestViewItem]> { get }
    var approveSignal: Signal<Any> { get }
    func approve()
}

struct WalletConnectRequestAmountViewItem {
    let primaryAmountInfo: AmountInfo
    let secondaryAmountInfo: AmountInfo?
}

enum WalletConnectRequestViewItem {
    case from(value: String)
    case to(value: String)
    case fee(coinValue: CoinValue, currencyValue: CurrencyValue?)
}
