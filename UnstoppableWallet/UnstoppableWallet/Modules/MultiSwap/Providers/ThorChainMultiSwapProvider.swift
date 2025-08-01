import Alamofire
import BigInt
import BitcoinCore
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import SwiftUI

class ThorChainMultiSwapProvider: IMultiSwapProvider {
    private let baseUrl = "https://thornode.ninerealms.com"

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

    private let affiliate: String? = AppConfig.thorchainAffiliate
    private let affiliateBps: Int? = AppConfig.thorchainAffiliateBps

    var assets = [Asset]()

    @Published private var useMevProtection: Bool = false

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage

        syncPools()
    }

    var id: String {
        "thorchain"
    }

    var name: String {
        "THORChain"
    }

    var icon: String {
        "thorchain_32"
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        let tokens = assets.map(\.token)
        return tokens.contains(tokenIn) && tokens.contains(tokenOut)
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        let swapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .avalanche, .base, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }

            let spenderAddress = try EvmKit.Address(hex: router)

            return await ThorChainMultiSwapEvmQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
                slippage: slippage,
                allowanceState: allowanceHelper.allowanceState(spenderAddress: spenderAddress, token: tokenIn, amount: amountIn)
            )
        case .bitcoin, .bitcoinCash, .litecoin:
            return ThorChainMultiSwapBtcQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
                slippage: slippage
            )
        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let slippage = slippage

        let slippageSwapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let swapQuote = slippageSwapQuote.slipProtectionThreshold > slippage ?
            slippageSwapQuote :
            try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage)

        switch tokenIn.blockchainType {
        case .avalanche, .base, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }

            let transactionData: TransactionData

            switch tokenIn.type {
            case .native:
                transactionData = try TransactionData(
                    to: EvmKit.Address(hex: swapQuote.inboundAddress),
                    value: tokenIn.fractionalMonetaryValue(value: amountIn),
                    input: Data(swapQuote.memo.utf8) // TODO: CHECK THIS POINT
                )
            case let .eip20(address):
                let method = try DepositWithExpiryMethod(
                    inboundAddress: EvmKit.Address(hex: swapQuote.inboundAddress),
                    asset: EvmKit.Address(hex: address),
                    amount: tokenIn.fractionalMonetaryValue(value: amountIn),
                    memo: swapQuote.memo,
                    expiry: BigUInt(UInt64(Date().timeIntervalSince1970) + 1 * 60 * 60) // TODO: CHECK THIS POINT
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

            if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPriceData {
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
        case .bitcoin, .bitcoinCash, .litecoin:
            var transactionError: Error?
            var satoshiPerByte: Int?
            var sendInfo: SendInfo?
            var params: SendParameters?

            if let _satoshiPerByte = transactionSettings?.satoshiPerByte,
               let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter
            {
                do {
                    satoshiPerByte = _satoshiPerByte
                    let _params = SendParameters(
                        address: swapQuote.inboundAddress,
                        value: adapter.convertToSatoshi(value: amountIn),
                        feeRate: _satoshiPerByte,
                        sortType: .none,
                        rbfEnabled: true,
                        memo: swapQuote.memo,
                        unspentOutputs: nil,
                        dustThreshold: swapQuote.dustThreshold,
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
        let allowMevProtection = MerkleTransactionAdapter.allowProtection(chain: evmBlockchainManager.chain(blockchainType: tokenIn.blockchainType))

        print("BASE_EVM_PROVIDER: Make Other Sections.")
        guard allowMevProtection else {
            print("BASE_EVM_PROVIDER: useMevProtection = false. Don't Show")
            useMevProtection = false
            return []
        }

        useMevProtection = localStorage.useMevProtection
        print("BASE_EVM_PROVIDER: set useMevProtection = \(useMevProtection). Show")

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
                    print("BASE_EVM_PROVIDER: set useMevProtection = \(newValue). Update")
                }

                guard Core.shared.purchaseManager.activated(.vipSupport) else {
                    Coordinator.shared.presentPurchases(onSuccess: successBlock)
                    return
                }

                successBlock()
            }
        )

        return [.init([
            .mevProtection(isOn: binding),
        ], isList: false)]
    }

    func settingsView(tokenIn: Token, tokenOut _: Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationStack {
            RecipientAndSlippageMultiSwapSettingsView(tokenIn: tokenIn, storage: storage, onChangeSettings: onChangeSettings)
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

            guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
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

        let amount = (amountIn * pow(10, 8)).rounded(decimal: 0)
        let destination = try resolveDestination(token: tokenOut)

        var parameters: Parameters = [
            "from_asset": assetIn.id,
            "to_asset": assetOut.id,
            "amount": amount.description,
            "destination": destination,
        ]

        if let slippage {
            parameters["tolerance_bps"] = Int((slippage * 100).rounded(decimal: 0).description)
        }

        if let affiliate, let affiliateBps {
            parameters["affiliate"] = affiliate
            parameters["affiliate_bps"] = affiliateBps
        }

        return try await networkManager.fetch(url: "\(baseUrl)/thorchain/quote/swap", parameters: parameters)
    }

    private func resolveDestination(token: Token) throws -> String {
        let blockchainType = token.blockchainType

        if let recipient = storage.recipient(blockchainType: blockchainType) {
            return recipient.raw
        }

        if let depositAdapter = adapterManager.adapter(for: token) as? IDepositAdapter {
            return depositAdapter.receiveAddress.address
        }

        guard let account = accountManager.activeAccount else {
            throw SwapError.noActiveAccount
        }

        switch blockchainType {
        case .avalanche, .base, .binanceSmartChain, .ethereum:
            let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

            guard let address = account.type.evmAddress(chain: chain) else {
                throw SwapError.noDestinationAddress
            }

            return address.eip55
        case .bitcoin:
            return try BitcoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .bitcoinCash:
            return try BitcoinCashAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        case .litecoin:
            return try LitecoinAdapter.firstAddress(accountType: account.type, tokenType: token.type)
        default:
            throw SwapError.noDestinationAddress
        }
    }

    private func syncPools() {
        Task { [weak self, networkManager, baseUrl] in
            let pools: [Pool] = try await networkManager.fetch(url: "\(baseUrl)/thorchain/pools")
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
            case .avalanche, .base, .binanceSmartChain, .ethereum:
                let components = assetId.components(separatedBy: "-")

                let tokenType: TokenType

                if components.count == 2 {
                    tokenType = .eip20(address: components[1])
                } else {
                    tokenType = .native
                }

                tokenQueries = [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

            case .bitcoinCash, .bitcoin:
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
        case "AVAX": return .avalanche
        case "BASE": return .base
        case "BCH": return .bitcoinCash
        case "BSC": return .binanceSmartChain
        case "BTC": return .bitcoin
        case "ETH": return .ethereum
        case "LTC": return .litecoin
        default: return nil
        }
    }

    private var slippage: Decimal {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default
    }
}

extension ThorChainMultiSwapProvider {
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

        let dustThreshold: Int

        init(map: Map) throws {
            inboundAddress = try map.value("inbound_address")
            expectedAmountOut = try map.value("expected_amount_out", using: Transform.stringToDecimalTransform) / pow(10, 8)
            memo = try map.value("memo")
            router = try? map.value("router")

            affiliateFee = try map.value("fees.affiliate", using: Transform.stringToDecimalTransform) / pow(10, 8)
            outboundFee = try map.value("fees.outbound", using: Transform.stringToDecimalTransform) / pow(10, 8)
            liquidityFee = try map.value("fees.liquidity", using: Transform.stringToDecimalTransform) / pow(10, 8)
            totalFee = try map.value("fees.total", using: Transform.stringToDecimalTransform) / pow(10, 8)

            dustThreshold = try map.value("dust_threshold", using: Transform.stringToIntTransform)
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
        case noActiveAccount
        case noDestinationAddress
        case noGasPrice
        case noGasLimit
        case noEvmKitWrapper
        case noBitcoinAdapter
        case noSendParameters
    }
}

extension ThorChainMultiSwapProvider {
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
