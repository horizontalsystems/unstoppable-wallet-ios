import MarketKit

enum DestinationHelper {
    static func resolveDestination(token: Token) async throws -> Destination {
        let blockchainType = token.blockchainType

        switch Core.shared.adapterManager.adapter(for: token) {
        case let adapter as ZcashAdapter:
            if let tAddress = adapter.tAddress?.stringEncoded {
                return .init(address: tAddress, type: .existing)
            }
        case let adapter as IDepositAdapter: return .init(address: adapter.receiveAddress.address, type: .existing)
        default: ()
        }

        guard let account = Core.shared.accountManager.activeAccount else {
            throw SwapError.noActiveAccount
        }

        if blockchainType.isEvm {
            let chain = try Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType)
            guard let address = account.type.evmAddress(chain: chain) else {
                throw SwapError.noDestinationAddress
            }

            return .init(address: address.eip55, type: .existing)
        }

        let address: String
        switch blockchainType {
        case .bitcoin:
            address = try BitcoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .bitcoinCash:
            address = try BitcoinCashAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .dash:
            address = try DashAdapter.firstAddress(accountType: account.type)
        case .litecoin:
            address = try LitecoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .tron:
            address = try Core.shared.tronAccountManager.address(type: account.type)
        case .stellar:
            address = try StellarKitManager.accountId(accountType: account.type)
        case .zcash:
            // provide transparent address for zcash swap
            address = try await ZcashAdapter.firstAddress(accountType: account.type, addressType: .transparent)
        default:
            throw SwapError.noDestinationAddress
        }

        return .init(address: address, type: .nonExisting)
    }
}

extension DestinationHelper {
    struct Destination {
        let address: String
        let type: ResolvedType
    }

    enum ResolvedType {
        case existing
        case nonExisting
    }

    enum SwapError: Error {
        case noActiveAccount
        case noDestinationAddress
    }
}
