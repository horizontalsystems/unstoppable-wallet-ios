import RxCocoa
import CurrencyKit
import EthereumKit
import BigInt

struct WalletConnectTransaction {
    let from: EthereumKit.Address
    let to: EthereumKit.Address
    let nonce: Int?
    let gasPrice: Int?
    let gasLimit: Int?
    let value: BigUInt
    let data: Data
}

enum WalletConnectRequestViewItem {
    case from(value: String)
    case to(value: String)
    case input(value: String)
}
