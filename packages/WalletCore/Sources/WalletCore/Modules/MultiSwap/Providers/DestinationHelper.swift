import BitcoinCore
import EvmKit
import Foundation
import MarketKit

public enum DestinationHelper {
    private static var shieldedUnifiedAddresses = [String: String]()
    private static let shieldedUnifiedLock = NSLock()

    // The account's unified address with shielded receivers only (Sapling + Orchard): a route memo or a refund target
    // then names no transparent receiver. The SDK stores a fresh diversified address on every call, and a confirmation
    // re-previews every 15 s, so one address is kept per account until the ZEC deposit is sent (the Zcash broadcaster
    // and send handler forget it): every re-preview of one operation names the same address. No fallback: without
    // the adapter there is nothing shielded-only to name.
    static func shieldedUnifiedAddress(token: Token) async throws -> String {
        guard let account = Core.shared.accountManager.activeAccount else {
            throw SwapError.noActiveAccount
        }

        if let cached = shieldedUnifiedLock.withLock({ shieldedUnifiedAddresses[account.id] }) {
            return cached
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter,
              let address = try await adapter.getCustomUnifiedAddress()?.stringEncoded
        else {
            throw SwapError.noDestinationAddress
        }

        shieldedUnifiedLock.withLock { shieldedUnifiedAddresses[account.id] = address }
        return address
    }

    static func forgetShieldedUnifiedAddress() {
        guard let accountId = Core.shared.accountManager.activeAccount?.id else {
            return
        }

        shieldedUnifiedLock.withLock { shieldedUnifiedAddresses[accountId] = nil }
    }

    public static func resolveDestinationUnified(token: Token, temporary: Destination? = nil) async throws -> Destination {
        if let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter,
           let uAddress = adapter.uAddress?.stringEncoded
        {
            return .init(address: uAddress, type: .existing)
        }

        if let temporary {
            return temporary
        }

        guard let account = Core.shared.accountManager.activeAccount else {
            throw SwapError.noActiveAccount
        }

        let address = try await ZcashAdapter.firstAddress(accountType: account.type, addressType: .shielded)
        return .init(address: address, type: .nonExisting)
    }

    public static func resolveDestination(token: Token, temporary: Destination? = nil) async throws -> Destination {
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
            let address = try AccountAddress.evmAddress(account: account, blockchainType: blockchainType)

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
            address = try AccountAddress.tronAddress(account: account).base58
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
        case .solana:
            address = try SolanaKitManager.address(accountType: account.type)
        case .xrp:
            address = try XrpKitManager.address(accountType: account.type)
        case .near:
            address = try Core.shared.nearKitManager.address(account: account)
        case .thorChain:
            address = try AccountAddress.thorChainAddress(account: account, network: .mainnet).raw
        case .mayaChain:
            address = try AccountAddress.thorChainAddress(account: account, network: .mayaMainnet).raw
        default:
            throw SwapError.noDestinationAddress
        }

        return .init(address: address, type: .nonExisting)
    }

    public static func sourceAddresses(token: Token, amountIn: Decimal, destinationAddress: String?) async -> [String] {
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
    public struct Destination {
        public let address: String
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
