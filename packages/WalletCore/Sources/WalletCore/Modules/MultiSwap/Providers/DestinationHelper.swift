import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import ZODLSwiftWalletSDK

extension ZcashReceiver {
    var receiverType: ReceiverType {
        switch self {
        case .orchard: .orchard
        case .sapling: .sapling
        case .transparent: .p2pkh
        }
    }
}

public enum DestinationHelper {
    private static var shieldedUnifiedAddresses = [String: String]()
    private static let shieldedUnifiedLock = NSLock()

    /// The account's unified address with shielded receivers only (Sapling + Orchard): a route memo or a refund target
    /// then names no transparent receiver. The SDK stores a fresh diversified address on every call, and a confirmation
    /// re-previews every 15 s, so one address is kept per account until the ZEC deposit is sent (the Zcash broadcaster
    /// and send handler forget it): every re-preview of one operation names the same address. No fallback: without
    /// the adapter there is nothing shielded-only to name.
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

        // two previews may miss the cache together: the first stored address wins, so one operation names one address
        return shieldedUnifiedLock.withLock {
            if let existing = shieldedUnifiedAddresses[account.id] {
                return existing
            }
            shieldedUnifiedAddresses[account.id] = address
            return address
        }
    }

    static func forgetShieldedUnifiedAddress() {
        guard let accountId = Core.shared.accountManager.activeAccount?.id else {
            return
        }

        shieldedUnifiedLock.withLock {
            shieldedUnifiedAddresses[accountId] = nil
            unifiedAddresses = unifiedAddresses.filter { $0.key.accountId != accountId }
        }
    }

    private struct UnifiedAddressKey: Hashable {
        let accountId: String
        let receivers: Set<ZcashReceiver>
    }

    private static var unifiedAddresses = [UnifiedAddressKey: String]()

    /// The account's unified address built from the receivers a route's `addressRules` name (a destination,
    /// refund or source for a unified-rule route). Cached per account and receiver set until the ZEC
    /// deposit is sent, for the same reason as `shieldedUnifiedAddress`: every re-preview of one operation
    /// must name the same address. No fallback: without the adapter there is nothing to build from.
    static func unifiedAddress(token: Token, receivers: [ZcashReceiver]) async throws -> String {
        guard let account = Core.shared.accountManager.activeAccount else {
            throw SwapError.noActiveAccount
        }

        let key = UnifiedAddressKey(accountId: account.id, receivers: Set(receivers))

        if let cached = shieldedUnifiedLock.withLock({ unifiedAddresses[key] }) {
            return cached
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter,
              let address = try await adapter.getCustomUnifiedAddress(receivers: Set(receivers.map(\.receiverType)))?.stringEncoded
        else {
            throw SwapError.noDestinationAddress
        }

        return shieldedUnifiedLock.withLock {
            if let existing = unifiedAddresses[key] {
                return existing
            }
            unifiedAddresses[key] = address
            return address
        }
    }

    /// The ZEC destination for a unified-rule route: the account's unified address built from `receivers`
    /// when the wallet runs, else the generated first shielded address (`nonExisting`, cached by the caller).
    static func resolveDestinationUnified(token: Token, receivers: [ZcashReceiver], temporary: Destination? = nil) async throws -> Destination {
        if Core.shared.adapterManager.adapter(for: token) is ZcashAdapter {
            let address = try await unifiedAddress(token: token, receivers: receivers)
            return .init(address: address, type: .existing)
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

    /// The addresses that fund a deposit: on a UTXO chain EVERY address holding a spendable
    /// output (a superset of whichever selection the deposit will make at the user's fee rate, so the AML
    /// precheck covers the real inputs), otherwise the single receive address. Empty when the sender
    /// cannot be determined.
    public static func sourceAddresses(token: Token) async -> [String] {
        let adapterManager = Core.shared.adapterManager

        if let adapter = adapterManager.adapter(for: token) as? ISendBitcoinAdapter {
            let outputs = adapter.unspentOutputs(filters: UtxoFilters())

            // An output whose address is unknown (missing or blank) could fund the deposit unchecked: the set is then
            // undeterminable, which the precheck treats as inconclusive (fails closed).
            guard outputs.allSatisfy({ !($0.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty }) else {
                return []
            }

            return Array(Set(outputs.compactMap(\.address))).sorted()
        }

        // Non-UTXO chains: return the single deposit/receive address
        if let adapter = adapterManager.adapter(for: token) as? IDepositAdapter {
            return [adapter.receiveAddress.address]
        }

        return []
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
