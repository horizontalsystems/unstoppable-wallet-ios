import EvmKit
import Foundation
import HsExtensions

public class MerkleSendRawTransactionJsonRpc: JsonRpc<Data> {
    public init(signedTransaction: Data, sourceTag: String) {
        super.init(
            method: "eth_sendRawTransaction",
            params: [signedTransaction.hs.hexString, sourceTag]
        )
    }

    override public func parse(result: Any) throws -> Data {
        guard let hexString = result as? String, let value = hexString.hs.hexData else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return value
    }
}
