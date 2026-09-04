import Combine
import Foundation
import MarketKit

public final class USwapAssetRepository {
    public static let blockchainTypeMap: [String: BlockchainType] = [
        "bitcoin": .bitcoin,
        "bitcoincash": .bitcoinCash,
        "ecash": .ecash,
        "litecoin": .litecoin,
        "dash": .dash,
        "zcash": .zcash,
        "monero": .monero,
        "1": .ethereum,
        "56": .binanceSmartChain,
        "137": .polygon,
        "43114": .avalanche,
        "10": .optimism,
        "42161": .arbitrumOne,
        "100": .gnosis,
        "250": .fantom,
        "728126428": .tron,
        "solana": .solana,
        "ton": .ton,
        "8453": .base,
        "324": .zkSync,
        "4663": .robinhood,
        "stellar": .stellar,
        "zano": .zano,
    ]

    private static let expiration: TimeInterval = 60 * 60

    private let providerId: String
    private let api: USwapMultiSwapApi
    private let storage: SwapAssetStorage
    private let includeAsset: @Sendable (String) -> Bool
    private let syncSubject = PassthroughSubject<Void, Never>()
    private let stateLock = NSLock()
    private var state: State

    public init(
        providerId: String,
        api: USwapMultiSwapApi,
        storage: SwapAssetStorage,
        includeAsset: @escaping @Sendable (String) -> Bool = { _ in true }
    ) {
        self.providerId = providerId
        self.api = api
        self.storage = storage
        self.includeAsset = includeAsset

        do {
            let storedAssetMap = try storage.swapAssetMap(provider: providerId, as: String.self)
            let assetMap = storedAssetMap.filter { includeAsset($0.value) }
            let lastSyncTimestamp: TimeInterval?

            if assetMap.count == storedAssetMap.count {
                lastSyncTimestamp = try? storage.lastSyncTimetamp(provider: providerId)
            } else {
                lastSyncTimestamp = nil
            }

            state = State(assetMap: assetMap, lastSyncTimestamp: lastSyncTimestamp)
        } catch {
            state = State(assetMap: [:], lastSyncTimestamp: nil)
        }

        sync()
    }

    deinit {
        stateLock.lock()
        let refreshTask = state.refreshTask
        state.refreshTask = nil
        stateLock.unlock()

        refreshTask?.cancel()
    }

    public var syncPublisher: AnyPublisher<Void, Never> {
        syncSubject.eraseToAnyPublisher()
    }

    public func asset(token: Token) -> String? {
        withState { state in
            state.assetMap[token.tokenQuery.id.lowercased()]
        }
    }

    public func sync() {
        let api = api
        let providerId = providerId
        let storage = storage
        let includeAsset = includeAsset

        withState { state in
            guard state.refreshTask == nil else {
                return
            }

            if let lastSyncTimestamp = state.lastSyncTimestamp,
               Date().timeIntervalSince1970 - lastSyncTimestamp < Self.expiration
            {
                return
            }

            state.refreshTask = Task { [weak self] in
                do {
                    try Task.checkCancellation()
                    let tokens = try await api.tokens(providerId: providerId)
                    try Task.checkCancellation()
                    let assetMap = Self.assetMap(tokens: tokens, includeAsset: includeAsset)
                    try Task.checkCancellation()

                    let timestamp = Date().timeIntervalSince1970
                    try? storage.save(swapAssetMap: assetMap, provider: providerId)
                    try? storage.save(lastSyncTimestamp: timestamp, provider: providerId)

                    await MainActor.run { [weak self] in
                        self?.finishSync(assetMap: assetMap, timestamp: timestamp)
                    }
                } catch {
                    self?.finishSync()
                }
            }
        }
    }
}

private extension USwapAssetRepository {
    struct State {
        var assetMap: [String: String]
        var lastSyncTimestamp: TimeInterval?
        var refreshTask: Task<Void, Never>?
    }

    func withState<T>(_ action: (inout State) -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return action(&state)
    }

    func finishSync(assetMap: [String: String], timestamp: TimeInterval) {
        withState { state in
            state.assetMap = assetMap
            state.lastSyncTimestamp = timestamp
            state.refreshTask = nil
        }

        syncSubject.send()
    }

    func finishSync() {
        withState { state in
            state.refreshTask = nil
        }
    }
}

extension USwapAssetRepository {
    static func assetMap(
        tokens: [USwapMultiSwapApi.Token],
        includeAsset: (String) -> Bool
    ) -> [String: String] {
        var assetMap = [String: String]()

        for token in tokens {
            guard includeAsset(token.identifier) else {
                continue
            }

            guard let blockchainType = blockchainTypeMap[token.chainId] else {
                continue
            }

            for tokenQuery in tokenQueries(
                blockchainType: blockchainType,
                address: token.address,
                ticker: token.ticker
            ) {
                assetMap[tokenQuery.id.lowercased()] = token.identifier
            }
        }

        return assetMap
    }
}

private extension USwapAssetRepository {
    static func tokenQueries(blockchainType: BlockchainType, address: String?, ticker: String?) -> [TokenQuery] {
        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .tron, .base, .zkSync, .robinhood:
            let tokenType: TokenType

            if let address, !address.isEmpty {
                tokenType = .eip20(address: address)
            } else {
                tokenType = .native
            }

            return [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .ton:
            let tokenType: TokenType

            if let address, !address.isEmpty {
                tokenType = .jetton(address: address)
            } else {
                tokenType = .native
            }

            return [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .solana:
            let tokenType: TokenType

            if let address, !address.isEmpty {
                tokenType = .spl(address: address)
            } else {
                tokenType = .native
            }

            return [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .stellar:
            if let issuer = address, !issuer.isEmpty {
                guard let ticker else {
                    return []
                }

                return [
                    TokenQuery(
                        blockchainType: .stellar,
                        tokenType: .stellar(code: ticker, issuer: issuer)
                    ),
                ]
            }

            return blockchainType.nativeTokenQueries

        case .bitcoin, .bitcoinCash, .ecash, .dash, .zcash, .monero:
            return blockchainType.nativeTokenQueries

        case .zano:
            if let assetId = address, !assetId.isEmpty {
                return [TokenQuery(blockchainType: .zano, tokenType: .zanoAsset(id: assetId))]
            } else {
                return blockchainType.nativeTokenQueries
            }

        case .litecoin:
            let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
            return supportedDerivations.map {
                TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
            }

        default:
            return []
        }
    }
}
