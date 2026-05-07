import EvmKit
import Foundation
import MarketKit

enum WalletConnectSendHandler {
    static func instance(request: WalletConnectRequest) -> ISendHandler? {
        switch request.payload {
        case is WCEthereumTransactionPayload: return WalletConnectEvmSendHandler.instance(request: request)
        case is WCStellarTransactionPayload: return WalletConnectStellarTransactionHandler.instance(request: request)
        default: return nil
        }
    }
}
