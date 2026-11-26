import MarketKit

extension NearPlugin: AccountCapability {
    func supports(accountType: AccountType, token: Token) -> Bool? {
        guard token.blockchainType == .near else {
            return nil
        }

        switch accountType {
        case .mnemonic, .nearAddress:
            switch token.type {
            case .native, .nep141: return true
            default: return false
            }
        default:
            return false
        }
    }

    var watchAddressSupports: [WatchAddressSupport] {
        [WatchAddressSupport(blockchainType: .near, priority: 1000)]
    }

    func watchAccountType(address: Address) throws -> AccountType? {
        address.blockchainType == .near ? .nearAddress(address: address.raw) : nil
    }
}

extension NearPlugin: TokenCapability {
    func addTokenService(blockchain: Blockchain) -> IAddTokenBlockchainService? {
        guard blockchain.type == .near else {
            return nil
        }

        return AddNearTokenBlockchainService(blockchain: blockchain, rpcUrls: nodeManager.rpcUrls(network: kitManager.network))
    }
}

extension NearPlugin: AddressCapability {
    func addressParserItems(blockchainType: BlockchainType, withEns _: Bool) -> [IAddressParserItem] {
        guard blockchainType == .near else {
            return []
        }

        return [NearAddressParserItem(rpcUrls: nodeManager.rpcUrls(network: kitManager.network))]
    }
}
