import MarketKit
import BitcoinKit
import BitcoinCore
import DashKit
import LitecoinKit
import BitcoinCashKit
import BinanceChainKit
import ZcashLightClientKit

class AddressParserFactory {

    static func parser(blockchainType: BlockchainType) -> AddressUriParser {
        switch blockchainType {
        case .bitcoin: return AddressUriParser(validScheme: "bitcoin", removeScheme: true)
        case .litecoin: return AddressUriParser(validScheme: "litecoin", removeScheme: true)
        case .bitcoinCash: return AddressUriParser(validScheme: "bitcoincash", removeScheme: false)
        case .dash: return AddressUriParser(validScheme: "dash", removeScheme: true)
        case .ethereum: return AddressUriParser(validScheme: "ethereum", removeScheme: true)
        case .binanceChain: return AddressUriParser(validScheme: "binance", removeScheme: true)
        case .zcash: return AddressUriParser(validScheme: "zcash", removeScheme: true)
        default: return AddressUriParser(validScheme: nil, removeScheme: false)
        }
    }

    static func parserChain(blockchainType: BlockchainType) -> AddressParserChain {
        switch blockchainType {
        case .bitcoin, .dash, .litecoin, .bitcoinCash:

            let network: INetwork
            switch blockchainType {
            case .dash: network = DashKit.MainNet()
            case .litecoin: network = LitecoinKit.MainNet()
            case .bitcoinCash: network = BitcoinCashKit.MainNet()
            default: network = BitcoinKit.MainNet()
            }
            let scriptConverter = ScriptConverter()

            let bech32AddressConverter = SegWitBech32AddressConverter(prefix: network.bech32PrefixPattern, scriptConverter: scriptConverter)
            let base58AddressConverter = Base58AddressConverter(addressVersion: network.pubKeyHash, addressScriptVersion: network.scriptHash)

            let addressConverterChain = AddressConverterChain()
            addressConverterChain.prepend(addressConverter: base58AddressConverter)
            addressConverterChain.prepend(addressConverter: bech32AddressConverter)

            let bitcoinTypeParserItem = BitcoinAddressParserItem(parserType: .converter(addressConverterChain))

            let udnAddressParserItem = UdnAddressParserItem.item(
                    rawAddressParserItem: bitcoinTypeParserItem,
                    coinCode: "BTC",       // todo: change on bitcoinCoinCode
                    token: nil)

            let addressParserChain = AddressParserChain()
                    .append(handler: bitcoinTypeParserItem)
                    .append(handler: udnAddressParserItem)

            if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
               let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: bitcoinTypeParserItem) {
                addressParserChain.append(handler: ensAddressParserItem)
            }

            return addressParserChain
        case .ethereum, .gnosis, .polygon, .arbitrumOne, .avalanche, .optimism, .binanceSmartChain, .ethereumGoerli:
            let evmAddressParserItem = EvmAddressParser()
            let udnAddressParserItem = UdnAddressParserItem.item(
                    rawAddressParserItem: evmAddressParserItem,
                    coinCode: "ETH",
                    token: nil)

            let addressParserChain = AddressParserChain()
                    .append(handler: evmAddressParserItem)
                    .append(handler: udnAddressParserItem)

            if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
               let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: evmAddressParserItem) {
                addressParserChain.append(handler: ensAddressParserItem)
            }

            return addressParserChain
        case .binanceChain:
            let network = BinanceChainKit.NetworkType.mainNet
            let validator = BinanceAddressValidator(prefix: network.addressPrefix)

            let binanceParserItem = BinanceAddressParserItem(parserType: .validator(validator))
            let addressParserChain = AddressParserChain()
                    .append(handler: binanceParserItem)

            return addressParserChain
        case .zcash:
            let network = ZcashNetworkBuilder.network(for: .mainnet)
            let validator = ZcashAddressValidator(network: network)
            let zcashParserItem = ZcashAddressParserItem(parserType: .validator(validator))
            let addressParserChain = AddressParserChain()
                    .append(handler: zcashParserItem)

            return addressParserChain
        default: return AddressParserChain()
        }

    }
}
