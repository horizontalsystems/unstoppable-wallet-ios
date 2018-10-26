class AdapterFactory: IAdapterFactory {

    func adapter(forCoin coin: Coin, words: [String]) -> IAdapter? {
        switch coin {
        case "BTC": return BitcoinAdapter(words: words, coin: .bitcoin(network: .mainNet))
        case "BTCt": return BitcoinAdapter(words: words, coin: .bitcoin(network: .testNet))
        case "BTCr": return BitcoinAdapter(words: words, coin: .bitcoin(network: .regTest))
        case "BCH": return BitcoinAdapter(words: words, coin: .bitcoinCash(network: .mainNet))
        case "BCHt": return BitcoinAdapter(words: words, coin: .bitcoinCash(network: .testNet))
        case "ETH": return EthereumAdapter(words: words, coin: .ethereum(network: .mainNet))
        case "ETHt": return EthereumAdapter(words: words, coin: .ethereum(network: .testNet))
        default: return nil
        }
    }

}
