class AdapterFactory: IAdapterFactory {

    func adapter(forCoin coin: Coin, authData: AuthData) -> IAdapter? {
        switch coin {
        case "BTC": return BitcoinAdapter(words: authData.words, coin: .bitcoin(network: .mainNet), walletId: authData.walletId)
        case "BTCt": return BitcoinAdapter(words: authData.words, coin: .bitcoin(network: .testNet), walletId: authData.walletId)
        case "BTCr": return BitcoinAdapter(words: authData.words, coin: .bitcoin(network: .regTest), walletId: authData.walletId)
        case "BCH": return BitcoinAdapter(words: authData.words, coin: .bitcoinCash(network: .mainNet), walletId: authData.walletId)
        case "BCHt": return BitcoinAdapter(words: authData.words, coin: .bitcoinCash(network: .testNet), walletId: authData.walletId)
        case "ETH": return EthereumAdapter(words: authData.words, coin: .ethereum(network: .mainNet))
        case "ETHt": return EthereumAdapter(words: authData.words, coin: .ethereum(network: .testNet))
        default: return nil
        }
    }

}
