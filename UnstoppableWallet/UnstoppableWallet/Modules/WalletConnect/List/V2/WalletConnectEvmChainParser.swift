import Foundation
import EthereumKit

class WalletConnectEvmChainParser {

    func parse(string: String) -> AccountData? {
        // todo: parse blockchain and return evm-chainId if it's possible

        let chunks = string.split(separator: ":")
        guard chunks.count >= 2 else {
            return nil
        }
        let chainId = Int(chunks[1])
        var address: String? = nil
        if chunks.count >= 3 {
            address = String(chunks[2])
        }

        return chainId.map { AccountData(eip: String(chunks[0]), chainId: $0, address: address) }
    }

}

extension WalletConnectEvmChainParser {

    struct AccountData {
        let eip: String
        let chainId: Int
        let address: String?
    }

}