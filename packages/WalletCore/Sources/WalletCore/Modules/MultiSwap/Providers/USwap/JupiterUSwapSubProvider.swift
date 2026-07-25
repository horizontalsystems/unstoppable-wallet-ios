import MarketKit

final class JupiterUSwapSubProvider: DefaultUSwapSubProvider {
    private static let wrappedSolMint = "So11111111111111111111111111111111111111112"

    override func asset(token: Token) -> String? {
        guard token.blockchainType == .solana else {
            return nil
        }

        switch token.type {
        case .native:
            return Self.wrappedSolMint
        case let .spl(address):
            guard address != Self.wrappedSolMint else {
                return nil
            }
            return address
        default:
            return nil
        }
    }
}
