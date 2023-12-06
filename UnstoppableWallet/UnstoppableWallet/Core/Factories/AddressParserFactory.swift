import BinanceChainKit
import BitcoinCashKit
import BitcoinCore
import BitcoinKit
import DashKit
import ECashKit
import LitecoinKit
import MarketKit
import ZcashLightClientKit

enum AddressParserFactory {
    static let uriBlockchainTypes: [BlockchainType] = [
        .bitcoin,
        .bitcoinCash,
        .ecash,
        .litecoin,
        .dash,
        .zcash,
        .ethereum,
        .binanceChain,
        .tron,
    ]

    static func parser(blockchainType: BlockchainType?, tokenType: TokenType?) -> AddressUriParser {
        AddressUriParser(blockchainType: blockchainType, tokenType: tokenType)
    }

    static func parserChainHandlers(blockchainType: BlockchainType, withEns: Bool = true) -> [IAddressParserItem] {
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

            let bitcoinTypeParserItem = BitcoinAddressParserItem(blockchainType: blockchainType, parserType: .converter(addressConverterChain))

            var handlers = [IAddressParserItem]()
            handlers.append(bitcoinTypeParserItem)
            if withEns {
                let udnAddressParserItem = UdnAddressParserItem.item(
                    rawAddressParserItem: bitcoinTypeParserItem,
                    blockchainType: blockchainType
                )
                handlers.append(udnAddressParserItem)
                if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
                   let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: bitcoinTypeParserItem)
                {
                    handlers.append(ensAddressParserItem)
                }
            }

            return handlers
        case .ethereum, .gnosis, .fantom, .polygon, .arbitrumOne, .avalanche, .optimism, .binanceSmartChain:
            let evmAddressParserItem = EvmAddressParser(blockchainType: blockchainType)

            var handlers = [IAddressParserItem]()
            handlers.append(evmAddressParserItem)
            if withEns {
                let udnAddressParserItem = UdnAddressParserItem.item(
                    rawAddressParserItem: evmAddressParserItem,
                    blockchainType: blockchainType
                )
                handlers.append(udnAddressParserItem)

                if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
                   let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: evmAddressParserItem)
                {
                    handlers.append(ensAddressParserItem)
                }
            }

            return handlers
        case .tron:
            return [TronAddressParser()]
        case .binanceChain:
            let network = BinanceChainKit.NetworkType.mainNet
            let validator = BinanceAddressValidator(prefix: network.addressPrefix)

            let binanceParserItem = BinanceAddressParserItem(parserType: .validator(validator))
            return [binanceParserItem]
        case .zcash:
            let network = ZcashNetworkBuilder.network(for: .mainnet)
            let validator = ZcashAddressValidator(network: network)
            let zcashParserItem = ZcashAddressParserItem(parserType: .validator(validator))

            return [zcashParserItem]
        case .solana: return []
        case .ton:
            return [TonAddressParserItem()]
        case .unsupported: return []
        }
    }

    static func parserChain(blockchainType: BlockchainType?, withEns: Bool = true) -> AddressParserChain {
        if let blockchainType {
            return AddressParserChain().append(handlers: parserChainHandlers(blockchainType: blockchainType, withEns: withEns))
        }

        var handlers = [IAddressParserItem]()
        for blockchainType in BlockchainType.supported {
            handlers.append(contentsOf: parserChainHandlers(blockchainType: blockchainType, withEns: withEns))
        }

        return AddressParserChain().append(handlers: handlers)
    }
}
