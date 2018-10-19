class AdapterFactory: IAdapterFactory {

    func adapter(forCoin coin: Coin, words: [String]) -> IAdapter? {
        switch coin {
        case "BTC": return BitcoinAdapter(words: words, networkType: .bitcoinMainNet)
        case "BTCt": return BitcoinAdapter(words: words, networkType: .bitcoinTestNet)
        case "BTCr": return BitcoinAdapter(words: words, networkType: .bitcoinRegTest)
        case "ETH": return EthereumAdapter(words: words, network: .mainnet)
        case "ETHt": return EthereumAdapter(words: words, network: .kovan)
        default: return nil
        }
    }

}
