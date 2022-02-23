import RxCocoa
import CurrencyKit
import EthereumKit
import BigInt
import UIKit

struct WalletConnectTransaction {
    let from: EthereumKit.Address
    let to: EthereumKit.Address
    let nonce: Int?
    let gasPrice: Int?
    let gasLimit: Int?
    let maxPriorityFeePerGas: Int?
    let maxFeePerGas: Int?
    let type: Int?
    let value: BigUInt
    let data: Data
}

struct WalletConnectRequestModule {

    static func viewController(signService: IWalletConnectSignService, request: WalletConnectRequest) -> UIViewController? {
        switch request {
        case let request as WalletConnectSignMessageRequest:
            let service = App.shared.walletConnectV2SessionManager.service
            return WalletConnectSignMessageRequestModule.viewController(signService: service, request: request)
        case let request as WalletConnectSendEthereumTransactionRequest:
            let service = App.shared.walletConnectV2SessionManager.service
            return WalletConnectSendEthereumTransactionRequestModule.viewController(signService: service, request: request)
        default: return nil
        }
    }

}