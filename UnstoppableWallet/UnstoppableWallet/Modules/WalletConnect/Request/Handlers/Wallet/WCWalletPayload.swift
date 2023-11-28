import Foundation
import WalletConnectSign

class WCWalletPayload: WCRequestPayload {
    class var method: String { "" }
    class var name: String { "" }
    override var method: String { Self.method }

    let chainId: Int

    init(dAppName: String, chainId: Int, data: Data) {
        self.chainId = chainId
        super.init(dAppName: dAppName, data: data)
    }

    public required convenience init(dAppName: String, from anyCodable: AnyCodable) throws {
        let chain = try anyCodable.get([WalletConnectChain].self)
        guard let chain = chain.first,
              let chainId = Int(chain.chainId.replacingOccurrences(of: "0x", with: ""), radix: 16)
        else {
            throw ParsingError.badJSONRPCRequest
        }

        self.init(dAppName: dAppName, chainId: chainId, data: chain.encoded)
    }
}

class WCWalletAddChainPayload: WCWalletPayload {
    override class var method: String { "wallet_addEthereumChain" }
    override class var name: String { "Add EVM Chain Request" }
}

class WCSwitchChainPayload: WCWalletPayload {
    override class var method: String { "wallet_switchEthereumChain" }
    override class var name: String { "Switch EVM Chain Request" }
}
