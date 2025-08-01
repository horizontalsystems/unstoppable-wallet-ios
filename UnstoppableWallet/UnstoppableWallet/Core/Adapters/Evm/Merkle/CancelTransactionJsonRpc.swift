import EvmKit
import Foundation
import HsExtensions

public class CancelTransactionJsonRpc: JsonRpc<Bool> {
    public init(hash: Data) {
        super.init(
            method: "eth_cancelTransaction",
            params: [hash.hs.hexString]
        )
    }

    override public func parse(result: Any) throws -> Bool {
        print("Result of Cancelling: \(result)")
        guard let value = result as? Bool else {
            print("Invalid Parsing!!!")
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return value
    }
}
