import MarketKit
import BitcoinKit
import BitcoinCore
import DashKit
import LitecoinKit
import BitcoinCashKit
import BinanceChainKit
import ZcashLightClientKit
import ECashKit

class AddressParserFactory {

    static func parser(blockchainType: BlockchainType?) -> AddressUriParser {
        switch blockchainType {
        case .bitcoin: return AddressUriParser(validScheme: "bitcoin", removeScheme: true)
        case .litecoin: return AddressUriParser(validScheme: "litecoin", removeScheme: true)
        case .bitcoinCash: return AddressUriParser(validScheme: "bitcoincash", removeScheme: false)
        case .ecash: return AddressUriParser(validScheme: "ecash", removeScheme: false)
        case .dash: return AddressUriParser(validScheme: "dash", removeScheme: true)
        case .ethereum: return AddressUriParser(validScheme: "ethereum", removeScheme: true)
        case .binanceChain: return AddressUriParser(validScheme: "binance", removeScheme: true)
        case .zcash: return AddressUriParser(validScheme: "zcash", removeScheme: true)
        default: return AddressUriParser(validScheme: nil, removeScheme: false)
        }
    }

    static func parserChain(blockchainType: BlockchainType) -> AddressParserChain {
        switch blockchainType {
        case .bitcoin, .dash, .litecoin, .bitcoinCash, .ecash:
            let scriptConverter = ScriptConverter()

            let specificAddressConverter: IAddressConverter?
            let network: INetwork
            switch blockchainType {
            case .dash:
                network = DashKit.MainNet()
                specificAddressConverter = nil
            case .litecoin:
                network = LitecoinKit.MainNet()
                specificAddressConverter = SegWitBech32AddressConverter(prefix: network.bech32PrefixPattern, scriptConverter: scriptConverter)
            case .bitcoinCash:
                network = BitcoinCashKit.MainNet()
                specificAddressConverter = CashBech32AddressConverter(prefix: network.bech32PrefixPattern)
            case .ecash:
                network = ECashKit.MainNet()
                specificAddressConverter = CashBech32AddressConverter(prefix: network.bech32PrefixPattern)
            default:
                network = BitcoinKit.MainNet()
                specificAddressConverter = SegWitBech32AddressConverter(prefix: network.bech32PrefixPattern, scriptConverter: scriptConverter)
            }
            let base58AddressConverter = Base58AddressConverter(addressVersion: network.pubKeyHash, addressScriptVersion: network.scriptHash)

            let addressConverterChain = AddressConverterChain()
            addressConverterChain.prepend(addressConverter: base58AddressConverter)
            if let specificAddressConverter {
                addressConverterChain.prepend(addressConverter: specificAddressConverter)
            }

            let bitcoinTypeParserItem = BitcoinAddressParserItem(parserType: .converter(addressConverterChain))

            let udnAddressParserItem = UdnAddressParserItem.item(
                    rawAddressParserItem: bitcoinTypeParserItem,
                    blockchainType: blockchainType)

            let addressParserChain = AddressParserChain()
                    .append(handler: bitcoinTypeParserItem)
                    .append(handler: udnAddressParserItem)

            if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
               let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: bitcoinTypeParserItem) {
                addressParserChain.append(handler: ensAddressParserItem)
            }

            return addressParserChain
        case .ethereum, .gnosis, .fantom, .polygon, .arbitrumOne, .avalanche, .optimism, .binanceSmartChain:
            let evmAddressParserItem = EvmAddressParser()

            let udnAddressParserItem = UdnAddressParserItem.item(
                    rawAddressParserItem: evmAddressParserItem,
                    blockchainType: blockchainType)

            let addressParserChain = AddressParserChain()
                    .append(handler: evmAddressParserItem)
                    .append(handler: udnAddressParserItem)

            if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
               let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: evmAddressParserItem) {
                addressParserChain.append(handler: ensAddressParserItem)
            }

            return addressParserChain
        case .tron:
            return AddressParserChain().append(handler: TronAddressParser())
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
        case .solana: return AddressParserChain()
        case .unsupported: return AddressParserChain()
        }

    }
}
