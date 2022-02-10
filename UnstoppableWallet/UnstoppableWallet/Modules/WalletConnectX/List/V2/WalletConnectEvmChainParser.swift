import Foundation

class WalletConnectEvmChainParser {

    public func chainId(blockchain: String) -> Int? {
        // todo: parse blockchain and return evm-chainId if it's possible

        let chunks = blockchain.split(separator: ":")
        if chunks.count >= 2 {
            return Int(chunks[1])
        }
        return nil
    }

}
