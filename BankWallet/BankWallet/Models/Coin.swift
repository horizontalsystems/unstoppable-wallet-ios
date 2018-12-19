enum CoinType {
    case bitcoin
    case bitcoinCash
    case ethereum
    case erc20(address: String, decimal: Int)
}

struct Coin {
    let title: String
    let code: CoinCode
    let type: CoinType
}
