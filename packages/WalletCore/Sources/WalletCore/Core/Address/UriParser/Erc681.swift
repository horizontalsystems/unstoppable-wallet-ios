import Foundation
import MarketKit

// `chainId != nil && blockchainType == nil` ⇒ caller must reject (unsupported chain).
struct Eip681PathParts {
    let address: String
    let chainId: Int?
    let blockchainType: BlockchainType?
    let function: String?
}

enum Erc681 {
    static func from(path: String) -> Eip681PathParts {
        let stripped = path.stripping(prefix: "pay-")
        let addressEnd = stripped.firstIndex(where: { $0 == "@" || $0 == "/" }) ?? stripped.endIndex
        let address = String(stripped[..<addressEnd])
        var rest = stripped[addressEnd...]

        var chainId: Int?
        var blockchainType: BlockchainType?
        if rest.first == "@" {
            rest = rest.dropFirst()
            let chainEnd = rest.firstIndex(of: "/") ?? rest.endIndex
            let chainPart = String(rest[..<chainEnd])
            rest = rest[chainEnd...]
            if !chainPart.isEmpty, let parsedId = Int(chainPart) {
                chainId = parsedId
                blockchainType = Core.shared.evmBlockchainManager.blockchain(chainId: parsedId)?.type
            }
        }

        var function: String?
        if rest.first == "/" {
            let functionPart = String(rest.dropFirst())
            if !functionPart.isEmpty {
                function = functionPart
            }
        }

        return Eip681PathParts(address: address, chainId: chainId, blockchainType: blockchainType, function: function)
    }
}
