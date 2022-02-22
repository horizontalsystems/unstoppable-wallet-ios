import Foundation
import EthereumKit

class WalletConnectEvmChainParser {

    public func parse(string: String) -> AccountData? {
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

    public func networkType(chainId: Int) -> NetworkType? {
        switch chainId {
        case 1: return .ethMainNet
        case 56: return .bscMainNet
        case 3: return .ropsten
        case 4: return .rinkeby
        case 42: return .kovan
        case 5: return .goerli
        default: return nil
        }
    }

}

extension WalletConnectEvmChainParser {

    struct AccountData {
        let eip: String
        let chainId: Int
        let address: String?
    }

}