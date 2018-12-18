enum BitcoinType {
    case bitcoin
    case bitcoinCash
}

enum EthereumType {
    case ethereum
    case erc20(address: String, decimal: Int)
}

enum BlockChain {
    case bitcoin(type: BitcoinType)
    case ethereum(type: EthereumType)
}

struct Coin {
    let title: String
    let code: CoinCode
    let blockChain: BlockChain
}
