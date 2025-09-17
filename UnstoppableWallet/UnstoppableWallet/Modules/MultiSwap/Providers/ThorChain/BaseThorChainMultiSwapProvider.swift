import Alamofire
import BigInt
import BitcoinCore
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import SwiftUI

class BaseThorChainMultiSwapProvider: IMultiSwapProvider {
    private let networkManager = Core.shared.networkManager
    // private let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))
    private let marketKit = Core.shared.marketKit
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let btcBlockchainManager = Core.shared.btcBlockchainManager
    private let accountManager = Core.shared.accountManager
    private let adapterManager = Core.shared.adapterManager
    private let localStorage = Core.shared.localStorage
    private let storage: MultiSwapSettingStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let evmFeeEstimator = EvmFeeEstimator()
    private let utxoFilters = UtxoFilters(
        scriptTypes: [.p2pkh, .p2wpkhSh, .p2wpkh],
        maxOutputsCountForInputs: 10
    )

    var assets = [Asset]()

    @Published private var useMevProtection: Bool = false

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage

        syncPools()
    }

    var baseUrl: String {
        fatalError("Must be overridden by subclass")
    }

    var id: String {
        fatalError("Must be overridden by subclass")
    }

    var name: String {
        fatalError("Must be overridden by subclass")
    }

    var icon: String {
        fatalError("Must be overridden by subclass")
    }

    var affiliate: String? {
        nil
    }

    var affiliateBps: Int? {
        nil
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        let tokens = assets.map(\.token)
        return tokens.contains(tokenIn) && tokens.contains(tokenOut)
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        let swapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }

            return await ThorChainMultiSwapEvmQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
                allowanceState: allowanceHelper.allowanceState(spenderAddress: .init(raw: router), token: tokenIn, amount: amountIn)
            )
        case .bitcoin, .bitcoinCash, .dash, .litecoin:
            return ThorChainMultiSwapBtcQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
            )
        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let swapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        let slippage = swapQuote.slipProtectionThreshold.rounded(decimal: 2)

        switch tokenIn.blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }

            let transactionData: TransactionData

            switch tokenIn.type {
            case .native:
                transactionData = try TransactionData(
                    to: EvmKit.Address(hex: swapQuote.inboundAddress),
                    value: tokenIn.fractionalMonetaryValue(value: amountIn),
                    input: Data(swapQuote.memo.utf8)
                )
            case let .eip20(address):
                let method = try DepositWithExpiryMethod(
                    inboundAddress: EvmKit.Address(hex: swapQuote.inboundAddress),
                    asset: EvmKit.Address(hex: address),
                    amount: tokenIn.fractionalMonetaryValue(value: amountIn),
                    memo: swapQuote.memo,
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

            if let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPriceData {
                do {
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                } catch {
                    transactionError = error
                }
            }

            return ThorChainMultiSwapEvmConfirmationQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
                slippage: slippage,
                transactionData: transactionData,
                transactionError: transactionError,
                gasPrice: gasPriceData?.userDefined,
                evmFeeData: evmFeeData,
                nonce: transactionSettings?.nonce
            )
        case .bitcoin, .bitcoinCash, .dash, .litecoin:
            var transactionError: Error?
            var satoshiPerByte: Int?
            var sendInfo: SendInfo?
            var params: SendParameters?

            if let _satoshiPerByte = transactionSettings?.satoshiPerByte,
               let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter
            {
                do {
                    let value = adapter.convertToSatoshi(value: amountIn)
                    if let dustThreshold = swapQuote.dustThreshold, value <= dustThreshold {
                        throw BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
                    }

                    satoshiPerByte = _satoshiPerByte
                    let _params = SendParameters(
                        address: swapQuote.inboundAddress,
                        value: value,
                        feeRate: _satoshiPerByte,
                        sortType: .none,
                        rbfEnabled: true,
                        memo: swapQuote.memo,
                        unspentOutputs: nil,
                        utxoFilters: utxoFilters,
                        changeToFirstInput: true
                    )

                    sendInfo = try adapter.sendInfo(params: _params)
                    params = _params
                } catch {
                    transactionError = error
                }
            }

            return ThorChainMultiSwapBtcConfirmationQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: tokenIn.blockchainType),
                slippage: slippage,
                satoshiPerByte: satoshiPerByte,
                fee: sendInfo?.fee,
                sendParameters: params,
                transactionError: transactionError
            )
        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func otherSections(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) -> [SendDataSection] {
        guard MerkleTransactionAdapter.allowProtection(blockchainType: tokenIn.blockchainType) else {
            useMevProtection = false
            return []
        }

        useMevProtection = localStorage.useMevProtection

        let binding = Binding<Bool>(
            get: { [weak self] in
                if Core.shared.purchaseManager.activated(.vipSupport) {
                    self?.useMevProtection ?? false
                } else {
                    false
                }
            },
            set: { [weak self] newValue in
                let successBlock = { [weak self] in
                    self?.useMevProtection = newValue
                    self?.localStorage.useMevProtection = newValue
                }

                guard Core.shared.purchaseManager.activated(.vipSupport) else {
                    // Coordinator.shared.presentPurchases(onSuccess: successBlock)
                    return
                }

                successBlock()
            }
        )

        return [.init([
            .mevProtection(isOn: binding),
        ], isList: false)]
    }

    func settingsView(tokenIn _: Token, tokenOut: Token, quote: IMultiSwapQuote, onChangeSettings: @escaping () -> Void) -> AnyView {
        guard let slippageProvider = quote as? IMultiSwapSlippageProvider else {
            let view = ThemeNavigationStack {
                RecipientMultiSwapSettingsView(tokenOut: tokenOut, storage: storage, onChangeSettings: onChangeSettings)
            }
            return AnyView(view)
        }

        let slippage = slippageProvider.slippage

        let view = ThemeNavigationStack {
            RecipientAndSlippageMultiSwapSettingsView(tokenOut: tokenOut, storage: storage, slippageMode: .fixed(slippage), onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func settingView(settingId _: String) -> AnyView {
        fatalError("settingView(settingId:) has not been implemented")
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        if let quote = quote as? ThorChainMultiSwapEvmConfirmationQuote {
            guard let gasLimit = quote.evmFeeData?.surchargedGasLimit else {
                throw SwapError.noGasLimit
            }

            guard let gasPrice = quote.gasPrice else {
                throw SwapError.noGasPrice
            }

            guard let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
                throw SwapError.noEvmKitWrapper
            }

            _ = try await evmKitWrapper.send(
                transactionData: quote.transactionData,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                privateSend: useMevProtection,
                nonce: quote.nonce
            )
        } else if let quote = quote as? ThorChainMultiSwapBtcConfirmationQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter else {
                throw SwapError.noBitcoinAdapter
            }

            guard let sendParameters = quote.sendParameters else {
                throw SwapError.noSendParameters
            }

            try adapter.send(params: sendParameters)
        }
    }

    private func swapQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal? = nil) async throws -> SwapQuote {
        guard let assetIn = assets.first(where: { $0.token == tokenIn }) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assets.first(where: { $0.token == tokenOut }) else {
            throw SwapError.unsupportedTokenOut
        }

        let amount = (amountIn * pow(10, 8)).roundedDown(decimal: 0)
        let destination = try resolveDestination(token: tokenOut)

        var parameters: Parameters = [
            "from_asset": assetIn.id,
            "to_asset": assetOut.id,
            "amount": amount.description,
            "destination": destination,
            "streaming_interval": 1,
            "streaming_quantity": 0,
        ]

        if let slippage {
            parameters["tolerance_bps"] = Int((slippage * 100).roundedDown(decimal: 0).description)
        }

        if let affiliate, let affiliateBps {
            parameters["affiliate"] = affiliate
            parameters["affiliate_bps"] = affiliateBps
        }

        return try await networkManager.fetch(url: "\(baseUrl)/quote/swap", parameters: parameters)
    }

    private func resolveDestination(token: Token) throws -> String {
        if let recipient = storage.recipient(blockchainType: token.blockchainType) {
            return recipient.raw
        }

        return try DestinationHelper.resolveDestination(token: token)
    }

    private func syncPools() {
        Task { [weak self, networkManager, baseUrl] in
            let pools: [Pool] = try await networkManager.fetch(url: "\(baseUrl)/pools")
            self?.sync(pools: pools)
        }
    }

    private func sync(pools: [Pool]) {
        assets = []

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
            case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum:
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

            case .litecoin:
                let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
                tokenQueries = supportedDerivations.map {
                    TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
                }

            default: ()
            }

            if let tokens = try? marketKit.tokens(queries: tokenQueries) {
                assets.append(contentsOf: tokens.map { Asset(id: pool.asset, token: $0) })
            }
        }
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
        // case "ZEC": return .zcash
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

    struct SwapQuote: ImmutableMappable {
        let inboundAddress: String
        let expectedAmountOut: Decimal
        let memo: String
        let router: String?

        let affiliateFee: Decimal
        let outboundFee: Decimal
        let liquidityFee: Decimal
        let totalFee: Decimal

        let dustThreshold: Int?

        init(map: Map) throws {
            inboundAddress = try map.value("inbound_address")
            expectedAmountOut = try map.value("expected_amount_out", using: Transform.stringToDecimalTransform) / pow(10, 8)
            memo = try map.value("memo")
            router = try? map.value("router")

            affiliateFee = try map.value("fees.affiliate", using: Transform.stringToDecimalTransform) / pow(10, 8)
            outboundFee = try map.value("fees.outbound", using: Transform.stringToDecimalTransform) / pow(10, 8)
            liquidityFee = try map.value("fees.liquidity", using: Transform.stringToDecimalTransform) / pow(10, 8)
            totalFee = try map.value("fees.total", using: Transform.stringToDecimalTransform) / pow(10, 8)

            dustThreshold = try? map.value("dust_threshold", using: Transform.stringToIntTransform)
        }

        var slipProtectionThreshold: Decimal {
            let totalValue = expectedAmountOut + totalFee
            return 100 - (expectedAmountOut * 100 / totalValue)
        }
    }

    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRouterAddress
        case invalidTokenInType
        case noDestinationAddress
        case noGasPrice
        case noGasLimit
        case noEvmKitWrapper
        case noBitcoinAdapter
        case noSendParameters
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
