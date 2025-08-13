import MarketKit

struct DestinationHelper {
    static func resolveDestination(token: Token) throws -> String {
        let blockchainType = token.blockchainType
        
        if let depositAdapter = Core.shared.adapterManager.adapter(for: token) as? IDepositAdapter {
            return depositAdapter.receiveAddress.address
        }
        
        guard let account = Core.shared.accountManager.activeAccount else {
            throw SwapError.noActiveAccount
        }
        
        if blockchainType.isEvm {
            let chain = Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType)
            
            guard let address = account.type.evmAddress(chain: chain) else {
                throw SwapError.noDestinationAddress
            }
            
            return address.eip55
        }

        switch blockchainType {
        case .bitcoin:
            return try BitcoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .bitcoinCash:
            return try BitcoinCashAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .litecoin:
            return try LitecoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .tron:
            return try Core.shared.tronAccountManager.address(type: account.type)
        case .stellar:
            return try StellarKitManager.accountId(accountType: account.type)
        default:
            throw SwapError.noDestinationAddress
        }
    }
}

extension DestinationHelper {
    enum SwapError: Error {
        case noActiveAccount
        case noDestinationAddress
    }

}
