import RxCocoa
import CurrencyKit
import EthereumKit
import BigInt

protocol IWalletConnectRequestViewModel {
    var amountViewItem: WalletConnectRequestAmountViewItem { get }
    var viewItems: [WalletConnectRequestViewItem] { get }
    var approveSignal: Signal<Data> { get }
    func approve()
}

struct WalletConnectTransaction {
    let from: Address
    let to: Address
    let nonce: Int?
    let gasPrice: Int?
    let gasLimit: Int
    let value: BigUInt
    let data: Data
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
