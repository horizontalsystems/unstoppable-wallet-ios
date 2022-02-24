import Foundation
import WalletConnect
import WalletConnectV1

struct WalletConnectV2RequestMapper {

    static func map(dAppName: String?, request: Request) throws -> WalletConnectRequest? {
        let chainId = request.chainId.flatMap {
            Int($0)
        }
        switch request.method {
        case "personal_sign":
            guard let params = try? request.params.get([String].self),
                  let dataString = params.first,
                  let data = Data(hex: dataString) else {
                return nil
            }
            return WalletConnectSignMessageRequest(
                    id: Int(request.id),
                    chainId: chainId,
                    dAppName: dAppName,
                    payload: WCEthereumSignPayload.personalSign(data: data, raw: params)
            )
        case "eth_signTypedData":
            guard let params = try? request.params.get([String].self),
                  params.count >= 2,
                  let data = params[1].data(using: .utf8) else {
                return nil
            }
            return WalletConnectSignMessageRequest(
                    id: Int(request.id),
                    chainId: chainId,
                    dAppName: dAppName,
                    payload: WCEthereumSignPayload.signTypeData(id: request.id, data: data, raw: params)
            )
        case "eth_sendTransaction":
            guard let transactions = try? request.params.get([WCEthereumTransaction].self),
                  !transactions.isEmpty else {
                return nil
            }
            return try WalletConnectSendEthereumTransactionRequest(
                    id: Int(request.id),
                    chainId: chainId,
                    dAppName: dAppName,
                    transaction: transactions[0]
            )
        default: return nil
        }
    }

}
