class AddressParserFactory {

    func parser(coin: Coin) -> IAddressParser {
        switch coin.type {
        case .bitcoin: return AddressParser(validScheme: "bitcoin", removeScheme: true)
        case .bitcoinCash: return AddressParser(validScheme: "bitcoincash", removeScheme: false)
        case .dash: return AddressParser(validScheme: "dash", removeScheme: true)
        case .ethereum: return AddressParser(validScheme: "ethereum", removeScheme: true)
        case .erc20: return AddressParser(validScheme: nil, removeScheme: true)
        case .eos: return AddressParser(validScheme: "eos", removeScheme: true)
        case .binance: return AddressParser(validScheme: "binance", removeScheme: true)
        }
    }

}
