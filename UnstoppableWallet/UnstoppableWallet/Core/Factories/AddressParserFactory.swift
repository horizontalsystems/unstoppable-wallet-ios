import MarketKit

class AddressParserFactory {

    static func parser(coinType: CoinType) -> IAddressUriParser {
        switch coinType {
        case .bitcoin: return AddressUriParser(validScheme: "bitcoin", removeScheme: true)
        case .litecoin: return AddressUriParser(validScheme: "litecoin", removeScheme: true)
        case .bitcoinCash: return AddressUriParser(validScheme: "bitcoincash", removeScheme: false)
        case .dash: return AddressUriParser(validScheme: "dash", removeScheme: true)
        case .ethereum: return AddressUriParser(validScheme: "ethereum", removeScheme: true)
        case .erc20: return AddressUriParser(validScheme: nil, removeScheme: true)
        case .binanceSmartChain: return AddressUriParser(validScheme: nil, removeScheme: true)
        case .bep20: return AddressUriParser(validScheme: nil, removeScheme: true)
        case .bep2: return AddressUriParser(validScheme: "binance", removeScheme: true)
        case .zcash: return AddressUriParser(validScheme: "zcash", removeScheme: true)
        default: return AddressUriParser(validScheme: nil, removeScheme: false)
        }
    }

}
