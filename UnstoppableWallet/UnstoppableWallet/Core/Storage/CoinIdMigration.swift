import CoinKit

class CoinIdMigration {
    private static let ids: [String: CoinType] = [
        "BNB-ERC20": .erc20(address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52"),
        "BNB": .bep2(symbol: "BNB"),
        "BNB-BSC": .binanceSmartChain,
        "DOS": .bep2(symbol: "DOS-120"),
        "DOS-ERC20": .erc20(address: "0x0A913beaD80F321E7Ac35285Ee10d9d922659cB7"),
        "ETH": .ethereum,
        "ETH-BEP2": .bep2(symbol: "ETH-1C9"),
        "MATIC": .erc20(address: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0"),
        "MATIC-BEP2": .bep2(symbol: "MATIC-84A"),
        "AAVEDAI": .erc20(address: "0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d"),
        "AMON": .erc20(address: "0x737f98ac8ca59f2c68ad658e3c3d8c8963e40a4c"),
        "RENBTC": .erc20(address: "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d"),
        "RENBCH": .erc20(address: "0x459086f2376525bdceba5bdda135e4e9d3fef5bf"),
        "RENZEC": .erc20(address: "0x1c5db575e2ff833e46a2e9864c22f4b22e0b37c2"),
    ]

    static func new(from old: String, coins: [Coin]) -> String? {
        if let coinType = ids[old] {
            return coinType.id
        }

        if let coin = coins.first(where: { coin in coin.code == old }) {
            return coin.id
        }

        if let coin = coins.first(where: { coin in
            if case .bep2(let symbol) = coin.type, old == symbol {
                return true
            }
            return false
        }) {
            return coin.id
        }

        return nil
    }

}
