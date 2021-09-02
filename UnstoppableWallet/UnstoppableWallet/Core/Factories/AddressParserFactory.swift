import MarketKit

class AddressParserFactory {

    func parser(coinType: CoinType) -> IAddressParser {
        switch coinType {
        case .bitcoin: return AddressParser(validScheme: "bitcoin", removeScheme: true)
        case .litecoin: return AddressParser(validScheme: "litecoin", removeScheme: true)
        case .bitcoinCash: return AddressParser(validScheme: "bitcoincash", removeScheme: false)
        case .dash: return AddressParser(validScheme: "dash", removeScheme: true)
        case .ethereum: return AddressParser(validScheme: "ethereum", removeScheme: true)
        case .erc20: return AddressParser(validScheme: nil, removeScheme: true)
        case .binanceSmartChain: return AddressParser(validScheme: nil, removeScheme: true)
        case .bep20: return AddressParser(validScheme: nil, removeScheme: true)
        case .bep2: return AddressParser(validScheme: "binance", removeScheme: true)
        case .zcash: return AddressParser(validScheme: "zcash", removeScheme: true)
        case .sol20, .unsupported: return AddressParser(validScheme: nil, removeScheme: false)
        }
    }

}
