import MarketKit

enum AddressSecurityCheckerFactory {
    static func securityCheckerChainHandlers(blockchainType: BlockchainType) -> [IAddressSecurityCheckerItem] {
        switch blockchainType {
        case .ethereum, .gnosis, .fantom, .polygon, .arbitrumOne, .avalanche, .optimism, .binanceSmartChain, .base:
            let evmAddressSecurityCheckerItem = SpamAddressDetector()
            let chainalysisAddressValidator = ChainalysisAddressValidator(networkManager: App.shared.networkManager)

            var handlers = [IAddressSecurityCheckerItem]()
            handlers.append(evmAddressSecurityCheckerItem)
            handlers.append(chainalysisAddressValidator)

            return handlers
        default:
            return []
        }
    }

    static func securityCheckerChain(blockchainType: BlockchainType?) -> AddressSecurityCheckerChain {
        if let blockchainType {
            return AddressSecurityCheckerChain().append(handlers: securityCheckerChainHandlers(blockchainType: blockchainType))
        }

        var handlers = [IAddressSecurityCheckerItem]()
        for blockchainType in BlockchainType.supported {
            handlers.append(contentsOf: securityCheckerChainHandlers(blockchainType: blockchainType))
        }

        return AddressSecurityCheckerChain().append(handlers: handlers)
    }
}
