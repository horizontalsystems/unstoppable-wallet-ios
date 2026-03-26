import BitcoinCore
import Foundation
import MarketKit

enum DestinationHelper {
    static func resolveDestination(token: Token, temporary: Destination? = nil) async throws -> Destination {
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

        if let temporary {
            return temporary
        }

        let address: String
        switch blockchainType {
        case .bitcoin:
            address = try BitcoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .bitcoinCash:
            address = try BitcoinCashAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .ecash:
            address = try ECashAdapter.firstAddress(accountType: account.type)
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
        case .ton:
            address = try TonKitManager.address(accountType: account.type)
        case .monero:
            address = MoneroAdapter.address(accountType: account.type)
        case .zano:
            address = ZanoAdapter.address(accountType: account.type)
        default:
            throw SwapError.noDestinationAddress
        }

        return .init(address: address, type: .nonExisting)
    }

    static func sourceAddresses(token: Token, amountIn: Decimal, destinationAddress: String?) async -> [String] {
        let adapterManager = Core.shared.adapterManager

        // UTXO chains: select the UTXOs that will actually cover amountIn
        if let adapter = adapterManager.adapter(for: token) as? ISendBitcoinAdapter {
            return await utxoSourceAddresses(adapter: adapter, token: token, amountIn: amountIn, destinationAddress: destinationAddress)
        }

        // Non-UTXO chains: return the single deposit/receive address
        if let adapter = adapterManager.adapter(for: token) as? IDepositAdapter {
            return [adapter.receiveAddress.address]
        }

        return []
    }

    private static func utxoSourceAddresses(adapter: ISendBitcoinAdapter, token: Token, amountIn: Decimal, destinationAddress: String?) async -> [String] {
        let feeRate: Int
        if let provider = Core.shared.feeRateProviderFactory.provider(blockchainType: token.blockchainType) {
            feeRate = await (try? provider.feeRates().recommended) ?? 1
        } else {
            feeRate = 1
        }

        let satoshiAmount = adapter.convertToSatoshi(value: amountIn)

        let params = SendParameters(
            address: destinationAddress,
            value: satoshiAmount,
            feeRate: feeRate
        )

        guard let sendInfo = try? adapter.sendInfo(params: params) else {
            return []
        }

        let addresses = sendInfo.unspentOutputs.compactMap(\.address)
        return Array(Set(addresses))
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
