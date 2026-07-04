import MarketKit

// Tokens that revert on a non-zero -> non-zero approve (canonical USDT): such an approve must be
// preceded by an approve(0). Pure domain rule, shared by the EOA pre-swap flow (MultiSwapAllowanceHelper)
// and the AA swap broadcaster.
public enum ApprovalReset {
    private static let addressesForRevoke: [BlockchainType: String] = [
        .ethereum: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        .tron: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
    ]

    public static func required(token: Token) -> Bool {
        for (blockchainType, addressToRevoke) in addressesForRevoke {
            if blockchainType == token.blockchainType, case let .eip20(address) = token.type, address.lowercased() == addressToRevoke.lowercased() {
                return true
            }
        }

        return false
    }
}
