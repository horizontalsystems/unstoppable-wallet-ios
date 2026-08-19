import Alamofire
import BigInt
import BitcoinCore
import Combine
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import SwiftUI
import ThorChainKit

public class BaseThorChainMultiSwapProvider: IMultiSwapProvider {
    private let assetMapExpiration: TimeInterval = 60 * 60
    // Bump to discard maps cached by older mapping logic.
    private let assetMapVersion = 4
    private var assetMapKey: String { "\(id)-v\(assetMapVersion)" }

    let networkManager = Core.shared.networkManager
//    let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))
    private let tracker: USwapTracker
    let adapterManager = Core.shared.adapterManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let swapAssetStorage = Core.shared.swapAssetStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let evmFeeEstimator = EvmFeeEstimator()
    private let utxoFilters = UtxoFilters(
        scriptTypes: [.p2pkh, .p2wpkhSh, .p2wpkh]
    )

    private var assetMap = [String: String]()
    private let syncSubject = PassthroughSubject<Void, Never>()

    public init(tracker: USwapTracker) {
        self.tracker = tracker
        assetMap = (try? swapAssetStorage.swapAssetMap(provider: assetMapKey, as: String.self)) ?? [:]
        syncAssets()
    }

    var baseUrl: String { fatalError("Must be overridden by subclass") }
    // THORChain exposes secured assets (BTC-BTC, ETH-ETH, …) via /securedassets and makes
    // them swappable through the standard `=:` memo. Maya has none, so it stays false.
    var securedAssetsSupported: Bool { false }
    public var id: String { fatalError("Must be overridden by subclass") }
    public var name: String { fatalError("Must be overridden by subclass") }
    public var type: SwapProviderType { fatalError("Must be overridden by subclass") }
    public var icon: String { fatalError("Must be overridden by subclass") }

    public var syncPublisher: AnyPublisher<Void, Never>? {
        syncSubject.eraseToAnyPublisher()
    }

    var affiliate: String? {
        nil
    }

    var affiliateBps: Int? {
        nil
    }

    var streamingInterval: Int { 1 }

    // The settlement coin backs every pool and is never listed among them: THOR.RUNE on
    // THORChain, MAYA.CACAO on Maya (where THOR.RUNE is an ordinary external pool).
    var settlementBlockchainType: BlockchainType { .thorChain }
    var settlementAsset: String { "THOR.RUNE" }

    // Base-unit scale the protocol quotes an amount in. Every pool asset is 1e8
    // regardless of its real decimals; the lone exception is the settlement chain's own
    // native coin, quoted in native decimals — 1e8 for RUNE, 1e10 for CACAO. Encoding
    // CACAO at 1e8 sends a 100x-too-small amount and the quote fails with
    // "not enough asset to pay for fees".
    func protocolDecimals(token: Token) -> Int {
        token.type == .native && token.blockchainType == settlementBlockchainType ? token.decimals : 8
    }

    public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        assetMap[tokenIn.tokenQuery.id.lowercased()] != nil && assetMap[tokenOut.tokenQuery.id.lowercased()] != nil
    }

    public func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        // Dry quote only: the account may be unable to receive tokenOut (external-recipient
        // swap), and a price can be quoted without a destination. Every confirmation path
        // resolves strictly — see swapQuote(allowMissingDestination:).
        let swapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, allowMissingDestination: true)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }

            return await EvmMultiSwapQuote(
                expectedBuyAmount: swapQuote.expectedAmountOut,
                allowanceState: allowanceHelper.allowanceState(spenderAddress: .init(raw: router), token: tokenIn, amount: amountIn),
                estimatedTime: estimatedTime(swapQuote, tokenOut: tokenOut)
            )
        case .bitcoin, .bitcoinCash, .dash, .litecoin, .zcash, .thorChain, .mayaChain:
            return MultiSwapQuote(expectedBuyAmount: swapQuote.expectedAmountOut, estimatedTime: swapQuote.totalSwapSeconds)
        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    public func confirmationQuote(multiSwapQuote _: MultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote {
        let swapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, recipient: recipient)

        // The memo carries the swap instruction; an inbound transfer without it is an
        // unrecoverable donation to the vault. swapQuote resolves the destination strictly
        // here, so a missing memo means the node itself withheld one.
        let memo = try swapQuote.requiredMemo()

        // the recipient is where the funds actually go; without one the account's own
        // address is resolved (and must resolve — else the swap has no destination)
        let toAddress = try await resolveDestination(recipient: recipient, token: tokenOut)

        switch tokenIn.blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }
            guard let inboundAddress = swapQuote.inboundAddress else {
                throw SwapError.noInboundAddress
            }

            let transactionData: TransactionData

            switch tokenIn.type {
            case .native:
                transactionData = try TransactionData(
                    to: EvmKit.Address(hex: inboundAddress),
                    value: tokenIn.fractionalMonetaryValue(value: amountIn),
                    input: Data(memo.utf8)
                )
            case let .eip20(address):
                let method = try DepositWithExpiryMethod(
                    inboundAddress: EvmKit.Address(hex: inboundAddress),
                    asset: EvmKit.Address(hex: address),
                    amount: tokenIn.fractionalMonetaryValue(value: amountIn),
                    memo: memo,
                    expiry: BigUInt(UInt64(Date().timeIntervalSince1970) + 1 * 60 * 60)
                )

                transactionData = try TransactionData(
                    to: EvmKit.Address(hex: router),
                    value: 0,
                    input: method.encodedABI()
                )
            default:
                throw SwapError.invalidTokenInType
            }

            let blockchainType = tokenIn.blockchainType
            let gasPriceData = transactionSettings?.gasPriceData
            var evmFeeData: EvmFeeData?
            var transactionError: Error?

            guard let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
                throw SwapError.noEvmKit
            }

            if let gasPriceData {
                do {
                    let _evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                    evmFeeData = _evmFeeData

                    try BaseEvmMultiSwapProvider.validateBalance(evmKitWrapper: evmKitWrapper, transactionData: transactionData, evmFeeData: _evmFeeData, gasPriceData: gasPriceData)
                } catch {
                    transactionError = error
                }
            }

            // router-approve intent: eip20 deposits pull via the router's transferFrom
            // (native deposits transfer directly to the inbound address and carry no approval)
            let approval = (try? EvmKit.Address(hex: router)).flatMap { SwapApproval.build(spender: $0, tokenIn: tokenIn, amountIn: amountIn) }

            return EvmSwapFinalQuote(
                expectedBuyAmount: swapQuote.expectedAmountOut,
                transactionData: transactionData,
                transactionError: transactionError,
                slippage: slippage,
                recipient: recipient,
                estimatedTime: estimatedTime(swapQuote, tokenOut: tokenOut),
                gasPrice: gasPriceData?.userDefined,
                evmFeeData: evmFeeData,
                nonce: transactionSettings?.nonce,
                approval: approval,
                toAddress: toAddress
            )
        case .bitcoin, .bitcoinCash, .dash, .litecoin:
            var transactionError: Error?
            var sendInfo: SendInfo?
            var params: SendParameters?

            guard let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter else {
                throw SwapError.noAdapter
            }

            if let satoshiPerByte = transactionSettings?.satoshiPerByte {
                do {
                    let value = adapter.convertToSatoshi(value: amountIn)
                    if let dustThreshold = swapQuote.dustThreshold, value <= dustThreshold {
                        throw BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
                    }

                    let _params = SendParameters(
                        address: swapQuote.inboundAddress,
                        value: value,
                        feeRate: satoshiPerByte,
                        memo: memo,
                        utxoFilters: utxoFilters,
                        changeToFirstInput: true
                    )

                    sendInfo = try adapter.sendInfo(params: _params)
                    params = _params
                } catch {
                    transactionError = error
                }
            }

            return UtxoSwapFinalQuote(
                expectedBuyAmount: swapQuote.expectedAmountOut,
                sendParameters: params,
                slippage: slippage,
                recipient: recipient,
                estimatedTime: swapQuote.totalSwapSeconds,
                transactionError: transactionError,
                fee: sendInfo?.fee,
                toAddress: toAddress
            )
        case .thorChain, .mayaChain:
            // A settlement-native input (RUNE, CACAO) has no vault to pay into and takes
            // a MsgDeposit; anything quoted with an inbound address is a plain transfer.
            let kind: ThorChainExecutable.Kind
            if let inboundAddress = swapQuote.inboundAddress {
                kind = try .send(recipient: ThorChainKit.Address(inboundAddress, network: tokenIn.blockchainType == .mayaChain ? .mayaMainnet : .mainnet))
            } else {
                guard let assetNotation = assetMap[tokenIn.tokenQuery.id.lowercased()] else {
                    throw SwapError.unsupportedTokenIn
                }
                kind = try .deposit(asset: ThorChainKit.Asset(notation: assetNotation))
            }

            let adapter = Core.shared.adapterManager.adapter(for: tokenIn) as? ThorChainAdapter
            // The fee is always paid in the chain's native coin, on top of the amount swapped.
            var transactionError: Error?
            if let adapter {
                let insufficient = adapter.isNativeCoin
                    ? amountIn + adapter.fee > adapter.availableBalance
                    : amountIn > adapter.availableBalance || adapter.fee > adapter.runeAvailableBalance
                if insufficient {
                    transactionError = ThorChainKit.SendError.insufficientBalance
                }
            }

            return ThorChainSwapFinalQuote(
                amountIn: amountIn,
                expectedAmountOut: swapQuote.expectedAmountOut,
                recipient: recipient,
                slippage: slippage,
                estimatedTime: swapQuote.totalSwapSeconds,
                kind: kind,
                memo: memo,
                fee: adapter?.fee,
                transactionError: transactionError,
                toAddress: toAddress
            )

        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    private func estimatedTime(_ swapQuote: SwapQuote, tokenOut: Token) -> TimeInterval {
        let inbound = swapQuote.inboundConfirmationSeconds ?? 0
        let swap = swapQuote.streamingSwapSeconds ?? 6
        let outbound = (swapQuote.outboundDelaySeconds ?? 6) + (tokenOut.blockchainType.blockTime ?? 6)
        return inbound + swap + outbound
    }

    public func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    public func track(swap: Swap) async throws -> Swap {
        // Native THORChain/Maya swaps aren't recorded by us → the stateless reader.
        try await tracker.track(
            swap: swap,
            request: .thorchain(
                providerId: swap.providerId,
                toAddress: swap.toAddress,
                inboundTxHash: swap.txHash,
                fromAsset: assetMap[swap.tokenIn.tokenQuery.id.lowercased()],
                toAsset: assetMap[swap.tokenOut.tokenQuery.id.lowercased()]
            )
        )
    }

    /// - Parameter allowMissingDestination: pass true ONLY for dry quotes. The account may be
    /// unable to receive tokenOut (external-recipient swap), and a price can be quoted without a
    /// destination — the node then answers without a memo, which a dry quote never reads. Every
    /// path that builds a signable transaction must leave this false: a quote whose destination
    /// silently failed to resolve carries no memo, and a memo-less inbound transfer is an
    /// unrecoverable donation to the vault.
    func swapQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal? = nil, recipient: String? = nil, params: Parameters? = nil, allowMissingDestination: Bool = false) async throws -> SwapQuote {
        guard let assetIn = assetMap[tokenIn.tokenQuery.id.lowercased()] else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assetMap[tokenOut.tokenQuery.id.lowercased()] else {
            throw SwapError.unsupportedTokenOut
        }

        let amount = (amountIn * pow(10, protocolDecimals(token: tokenIn))).roundedDown(decimal: 0)

        let destination: String?
        if allowMissingDestination {
            destination = try? await resolveDestination(recipient: recipient, token: tokenOut)
        } else {
            destination = try await resolveDestination(recipient: recipient, token: tokenOut)
        }

        var parameters: Parameters = [
            "from_asset": assetIn,
            "to_asset": assetOut,
            "amount": amount.description,
            "streaming_interval": streamingInterval,
            "streaming_quantity": 0,
        ]

        if let destination {
            parameters["destination"] = destination
        }

        if let slippage {
            parameters["liquidity_tolerance_bps"] = Int((slippage * 100).roundedDown(decimal: 0).description)
        }

        if let affiliate, let affiliateBps {
            parameters["affiliate"] = affiliate
            parameters["affiliate_bps"] = affiliateBps
        }

        if let params {
            parameters.merge(params) { _, custom in
                custom
            }
        }

        let quote: SwapQuote = try await networkManager.fetch(url: "\(baseUrl)/quote/swap", parameters: parameters)
        // The decoder normalizes at 1e8; a settlement-native output (and its fees, which
        // the node denominates in the output asset) arrives at native decimals instead.
        return quote.rescalingOutput(extraDecimals: protocolDecimals(token: tokenOut) - 8)
    }

    func resolveDestination(recipient: String?, token: Token) async throws -> String {
        if let recipient {
            return recipient
        }

        return try await DestinationHelper.resolveDestination(token: token).address
    }

    private func syncAssets() {
        let lastSyncTimetamp = try? swapAssetStorage.lastSyncTimetamp(provider: assetMapKey)

        if let lastSyncTimetamp, Date().timeIntervalSince1970 - lastSyncTimetamp < assetMapExpiration {
            return
        }

        Task { [weak self, networkManager, baseUrl, securedAssetsSupported] in
            let pools: [Pool] = try await networkManager.fetch(url: "\(baseUrl)/pools")

            // Secured assets live in x/bank, not /pools. Fetched defensively: a
            // /securedassets outage must not discard the pool-based map.
            var securedAssets = [SecuredAsset]()
            if securedAssetsSupported {
                securedAssets = await (try? networkManager.fetch(url: "\(baseUrl)/securedassets") as [SecuredAsset]) ?? []
            }

            self?.sync(pools: pools, securedAssets: securedAssets)
        }
    }

    private func sync(pools: [Pool], securedAssets: [SecuredAsset]) {
        var assetMap = [String: String]()

        let availablePools = pools.filter { $0.status.caseInsensitiveCompare("available") == .orderedSame }

        for pool in availablePools {
            let components = pool.asset.components(separatedBy: ".")

            guard let assetBlockchainId = components.first, let assetId = components.last else {
                continue
            }

            guard let blockchainType = blockchainType(assetBlockchainId: assetBlockchainId) else {
                continue
            }

            var tokenQueries: [TokenQuery] = []

            switch blockchainType {
            case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .stellar:
                let components = assetId.components(separatedBy: "-")

                let tokenType: TokenType

                if components.count == 2 {
                    tokenType = .eip20(address: components[1])
                } else {
                    tokenType = .native
                }

                tokenQueries = [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

            case .bitcoinCash, .bitcoin, .dash, .zcash:
                tokenQueries = blockchainType.nativeTokenQueries

            case .thorChain:
                guard let asset = try? ThorChainKit.Asset(notation: pool.asset) else { continue }
                let denom = ThorChainKit.Denom.denom(for: asset)
                tokenQueries = [TokenQuery(blockchainType: .thorChain, tokenType: denom == "rune" ? .native : .thorChainAsset(denom: denom))]

            case .litecoin:
                let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
                tokenQueries = supportedDerivations.map {
                    TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
                }

            default: ()
            }

            for tokenQuery in tokenQueries {
                assetMap[tokenQuery.id.lowercased()] = pool.asset
            }
        }

        assetMap[TokenQuery(blockchainType: settlementBlockchainType, tokenType: .native).id.lowercased()] = settlementAsset

        assetMap.merge(Self.securedAssetMapEntries(securedAssets: securedAssets)) { _, secured in secured }

        try? swapAssetStorage.save(swapAssetMap: assetMap, provider: assetMapKey)
        try? swapAssetStorage.save(lastSyncTimestamp: Date().timeIntervalSince1970, provider: assetMapKey)

        DispatchQueue.main.async {
            self.assetMap = assetMap
            self.syncSubject.send()
        }
    }

    static func securedAssetMapEntries(securedAssets: [SecuredAsset]) -> [String: String] {
        var entries = [String: String]()

        for securedAsset in securedAssets {
            guard let asset = try? ThorChainKit.Asset(notation: securedAsset.asset) else { continue }
            let denom = ThorChainKit.Denom.denom(for: asset)
            entries[TokenQuery(blockchainType: .thorChain, tokenType: .thorChainAsset(denom: denom)).id.lowercased()] = securedAsset.asset
        }

        return entries
    }

    private func blockchainType(assetBlockchainId: String) -> BlockchainType? {
        switch assetBlockchainId {
        case "ARB": return .arbitrumOne
        case "AVAX": return .avalanche
        case "BASE": return .base
        case "BCH": return .bitcoinCash
        case "BSC": return .binanceSmartChain
        case "BTC": return .bitcoin
        case "DASH": return .dash
        case "ETH": return .ethereum
        case "LTC": return .litecoin
        case "ZEC": return .zcash
        case "THOR": return .thorChain
        default: return nil
        }
    }
}

extension BaseThorChainMultiSwapProvider {
    struct Asset {
        let id: String
        let token: Token
    }

    struct Pool: ImmutableMappable {
        let asset: String
        let status: String

        init(map: Map) throws {
            asset = try map.value("asset")
            status = try map.value("status")
        }
    }

    // /securedassets also reports supply and depth; only the asset notation is needed.
    struct SecuredAsset: ImmutableMappable {
        let asset: String

        init(map: Map) throws {
            asset = try map.value("asset")
        }
    }

    struct SwapQuote: ImmutableMappable {
        // Absent when the input is THORChain-native: there is no vault to pay into.
        let inboundAddress: String?
        var expectedAmountOut: Decimal
        // nil when the quote was requested without a destination — see swapQuote(allowMissingDestination:)
        let memo: String?
        let router: String?

        var affiliateFee: Decimal
        var outboundFee: Decimal
        var liquidityFee: Decimal
        var totalFee: Decimal

        let dustThreshold: Int?
        let inboundConfirmationSeconds: TimeInterval?
        let outboundDelaySeconds: TimeInterval?
        let streamingSwapSeconds: TimeInterval?
        let totalSwapSeconds: TimeInterval?

        init(map: Map) throws {
            // Absent when the input asset is THORChain-native: there is no vault to pay
            // into. Only absence may mean that — a value of the wrong shape is a broken
            // quote, and reading it as absence would turn it into a deposit.
            if map.JSON["inbound_address"] == nil {
                inboundAddress = nil
            } else {
                inboundAddress = try map.value("inbound_address")
            }
            expectedAmountOut = try map.value("expected_amount_out", using: Transform.stringToDecimalTransform) / pow(10, 8)
            // Absent when the quote was requested without a destination (dry quote for a
            // tokenOut the account can't hold). Optional rather than a "" sentinel so every
            // consumer that turns a memo into a signed transfer must handle its absence —
            // a memo-less inbound transfer is an unrecoverable donation to the vault.
            memo = try? map.value("memo")
            router = try? map.value("router")

            affiliateFee = try map.value("fees.affiliate", using: Transform.stringToDecimalTransform) / pow(10, 8)
            outboundFee = try map.value("fees.outbound", using: Transform.stringToDecimalTransform) / pow(10, 8)
            liquidityFee = try map.value("fees.liquidity", using: Transform.stringToDecimalTransform) / pow(10, 8)
            totalFee = try map.value("fees.total", using: Transform.stringToDecimalTransform) / pow(10, 8)

            dustThreshold = try? map.value("dust_threshold", using: Transform.stringToIntTransform)

            inboundConfirmationSeconds = try? map.value("inbound_confirmation_seconds")
            outboundDelaySeconds = try? map.value("outbound_delay_seconds")
            streamingSwapSeconds = try? map.value("streaming_swap_seconds")
            totalSwapSeconds = try? map.value("total_swap_seconds")
        }

        /// The swap instruction to attach to the inbound transfer. Throws instead of
        /// returning an empty string: every caller here turns the result into a signed
        /// transfer, and a memo-less one is an unrecoverable donation to the vault.
        func requiredMemo() throws -> String {
            guard let memo, !memo.isEmpty else {
                throw SwapError.noMemo
            }

            return memo
        }

        func rescalingOutput(extraDecimals: Int) -> SwapQuote {
            guard extraDecimals != 0 else { return self }
            let divisor = pow(10, extraDecimals)
            var copy = self
            copy.expectedAmountOut /= divisor
            copy.affiliateFee /= divisor
            copy.outboundFee /= divisor
            copy.liquidityFee /= divisor
            copy.totalFee /= divisor
            return copy
        }
    }

    enum SwapError: Error, LocalizedError {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRouterAddress
        case noInboundAddress
        case invalidTokenInType
        case noAdapter
        case noEvmKit
        case noMemo

        public var errorDescription: String? {
            switch self {
            // The only case a user can hit on a quote that looked valid a moment earlier,
            // so it is the one that must not surface as a raw enum name.
            case .noMemo: return "swap.error.no_memo".localized
            default: return nil
            }
        }
    }
}

extension BaseThorChainMultiSwapProvider {
    class DepositWithExpiryMethod: ContractMethod {
        static let methodSignature = "depositWithExpiry(address,address,uint256,string,uint256)"

        let inboundAddress: EvmKit.Address
        let asset: EvmKit.Address
        let amount: BigUInt
        let memo: String
        let expiry: BigUInt

        init(inboundAddress: EvmKit.Address, asset: EvmKit.Address, amount: BigUInt, memo: String, expiry: BigUInt) {
            self.inboundAddress = inboundAddress
            self.asset = asset
            self.amount = amount
            self.memo = memo
            self.expiry = expiry

            super.init()
        }

        override var methodSignature: String { Self.methodSignature }
        override var arguments: [Any] { [inboundAddress, asset, amount, memo, expiry] }
    }
}
