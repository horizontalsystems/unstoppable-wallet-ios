import MarketKit

final class LifiUSwapSubProvider: DefaultUSwapSubProvider {
    private static let nativeEvmAsset = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    private static let wrappedSolMint = "So11111111111111111111111111111111111111112"

    private static let chainCodes: [BlockchainType: String] = [
        .ethereum: "ETH",
        .polygon: "POL",
        .arbitrumOne: "ARB",
        .optimism: "OP",
        .base: "BASE",
        .avalanche: "AVAX",
        .binanceSmartChain: "BSC",
    ]

    override func asset(token: Token) -> String? {
        if token.blockchainType == .solana {
            switch token.type {
            case .native:
                return "SOL.\(Self.wrappedSolMint)"
            case let .spl(address):
                guard address != Self.wrappedSolMint else {
                    return nil
                }
                return "SOL.\(address)"
            default:
                return nil
            }
        }

        if token.blockchainType == .tron {
            switch token.type {
            case .native:
                return "TRON.TRX"
            case let .eip20(address):
                return "TRON.\(address)"
            default:
                return nil
            }
        }

        guard let chainCode = Self.chainCodes[token.blockchainType] else {
            return nil
        }

        switch token.type {
        case .native:
            return "\(chainCode).\(Self.nativeEvmAsset)"
        case let .eip20(address):
            return "\(chainCode).\(address)"
        default:
            return nil
        }
    }
}
