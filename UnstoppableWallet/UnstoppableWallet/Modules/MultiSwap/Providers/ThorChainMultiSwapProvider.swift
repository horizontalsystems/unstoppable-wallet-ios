import Alamofire
import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import SwiftUI

class ThorChainMultiSwapProvider: IMultiSwapProvider {
    private let baseUrl = "https://thornode.ninerealms.com"

    private let networkManager = App.shared.networkManager
//    private let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))
    private let marketKit = App.shared.marketKit
    private let evmBlockchainManager = App.shared.evmBlockchainManager
    private let accountManager = App.shared.accountManager
    private let adapterManager = App.shared.adapterManager
    private let storage: MultiSwapSettingStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let evmFeeEstimator = EvmFeeEstimator()

    var assets = [Asset]()

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
        case .avalanche, .binanceSmartChain, .ethereum:
            guard let router = swapQuote.router else {
                throw SwapError.noRouterAddress
            }

            let spenderAddress = try EvmKit.Address(hex: router)

            return await EvmQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
                slippage: slippage,
                allowanceState: allowanceHelper.allowanceState(spenderAddress: spenderAddress, token: tokenIn, amount: amountIn)
            )
        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let swapQuote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        switch tokenIn.blockchainType {
        case .avalanche, .binanceSmartChain, .ethereum:
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
            let gasPrice = transactionSettings?.gasPrice
            var evmFeeData: EvmFeeData?
            var transactionError: Error?

            if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPrice {
                do {
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPrice: gasPrice)
                } catch {
                    transactionError = error
                }
            }

            return EvmConfirmationQuote(
                swapQuote: swapQuote,
                recipient: storage.recipient(blockchainType: blockchainType),
                slippage: slippage,
                transactionData: transactionData,
                transactionError: transactionError,
                gasPrice: gasPrice,
                evmFeeData: evmFeeData,
                nonce: transactionSettings?.nonce
            )
        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func settingsView(tokenIn: Token, tokenOut _: Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
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

    func swap(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, quote _: IMultiSwapConfirmationQuote) async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000) // todo
    }

    private func swapQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> SwapQuote {
        guard let assetIn = assets.first(where: { $0.token == tokenIn }) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assets.first(where: { $0.token == tokenOut }) else {
            throw SwapError.unsupportedTokenOut
        }

        let amount = (amountIn * pow(10, 8)).rounded(decimal: 0)
        let destination = try resolveDestination(token: tokenOut)

        let parameters: Parameters = [
            "from_asset": assetIn.id,
            "to_asset": assetOut.id,
            "amount": amount.description,
            "destination": destination,
//            "tolerance_bps": slippage * 100
        ]

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
        case .avalanche, .binanceSmartChain, .ethereum:
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
        case .binanceChain:
            return try BinanceAdapter.address(accountType: account.type)
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

            switch blockchainType {
            case .avalanche, .binanceSmartChain, .ethereum:
                let components = assetId.components(separatedBy: "-")

                let tokenType: TokenType

                if components.count == 2 {
                    tokenType = .eip20(address: components[1])
                } else {
                    tokenType = .native
                }

                let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: tokenType))

                if let token {
                    assets.append(Asset(id: pool.asset, token: token))
                }
            case .bitcoinCash, .bitcoin, .litecoin:
                let tokens = try? marketKit.tokens(queries: blockchainType.nativeTokenQueries)

                if let tokens {
                    assets.append(contentsOf: tokens.map { Asset(id: pool.asset, token: $0) })
                }
            case .binanceChain:
                let tokenType: TokenType

                if assetId == "BNB" {
                    tokenType = .native
                } else {
                    tokenType = .bep2(symbol: assetId)
                }

                let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: tokenType))

                if let token {
                    assets.append(Asset(id: pool.asset, token: token))
                }
            default: ()
            }
        }
    }

    private func blockchainType(assetBlockchainId: String) -> BlockchainType? {
        switch assetBlockchainId {
        case "AVAX": return .avalanche
        case "BCH": return .bitcoinCash
        case "BNB": return .binanceChain
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

        init(map: Map) throws {
            inboundAddress = try map.value("inbound_address")
            expectedAmountOut = try map.value("expected_amount_out", using: Transform.stringToDecimalTransform) / pow(10, 8)
            memo = try map.value("memo")
            router = try? map.value("router")

            affiliateFee = try map.value("fees.affiliate", using: Transform.stringToDecimalTransform) / pow(10, 8)
            outboundFee = try map.value("fees.outbound", using: Transform.stringToDecimalTransform) / pow(10, 8)
            liquidityFee = try map.value("fees.liquidity", using: Transform.stringToDecimalTransform) / pow(10, 8)
        }
    }

    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRouterAddress
        case invalidTokenInType
        case noActiveAccount
        case noDestinationAddress
    }
}

extension ThorChainMultiSwapProvider {
    class EvmQuote: BaseEvmMultiSwapProvider.Quote {
        let swapQuote: SwapQuote
        let recipient: Address?
        let slippage: Decimal

        init(swapQuote: SwapQuote, recipient: Address?, slippage: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
            self.swapQuote = swapQuote
            self.recipient = recipient
            self.slippage = slippage

            super.init(allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            swapQuote.expectedAmountOut
        }

        override var settingsModified: Bool {
            super.settingsModified || recipient != nil || slippage != MultiSwapSlippage.default
        }

        override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
            var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

            if let recipient {
                fields.append(
                    MultiSwapMainField(
                        title: "swap.recipient".localized,
                        value: recipient.title,
                        valueLevel: .regular
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    MultiSwapMainField(
                        title: "swap.slippage".localized,
                        value: "\(slippage.description)%",
                        valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            return fields
        }

        override func cautions() -> [CautionNew] {
            var cautions = super.cautions()

            switch MultiSwapSlippage.validate(slippage: slippage) {
            case .none: ()
            case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
            }

            return cautions
        }
    }

    class EvmConfirmationQuote: BaseEvmMultiSwapProvider.ConfirmationQuote {
        let swapQuote: SwapQuote
        let recipient: Address?
        let slippage: Decimal
        let transactionData: TransactionData
        let transactionError: Error?

        init(swapQuote: SwapQuote, recipient: Address?, slippage: Decimal, transactionData: TransactionData, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
            self.swapQuote = swapQuote
            self.recipient = recipient
            self.slippage = slippage
            self.transactionData = transactionData
            self.transactionError = transactionError

            super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
        }

        override var amountOut: Decimal {
            swapQuote.expectedAmountOut
        }

        override func cautions(feeToken: MarketKit.Token?) -> [CautionNew] {
            var cautions = super.cautions(feeToken: feeToken)

            if let transactionError {
                cautions.append(caution(transactionError: transactionError, feeToken: feeToken))
            }

            switch MultiSwapSlippage.validate(slippage: slippage) {
            case .none: ()
            case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
            }

            return cautions
        }

        override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
            var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if let recipient {
                fields.append(
                    .address(
                        title: "swap.recipient".localized,
                        value: recipient.title,
                        blockchainType: tokenOut.blockchainType
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    .levelValue(
                        title: "swap.slippage".localized,
                        value: "\(slippage.description)%",
                        level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

//            let minAmountOut = amountOut * (1 - slippage / 100)
//
//            fields.append(
//                .value(
//                    title: "swap.confirmation.minimum_received".localized,
//                    description: nil,
//                    coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
//                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) },
//                    formatFull: true
//                )
//            )

            return fields
        }

        override func otherSections(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
            var sections = super.otherSections(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if let feeToken, let tokenOutRate, let evmFeeData,
               let evmFeeAmountData = evmFeeData.totalAmountData(gasPrice: gasPrice, feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate),
               let evmFeeCurrencyValue = evmFeeAmountData.currencyValue
            {
                let totalFee = evmFeeCurrencyValue.value + (swapQuote.affiliateFee + swapQuote.liquidityFee + swapQuote.outboundFee) * tokenOutRate
                let currencyValue = CurrencyValue(currency: currency, value: totalFee)

                if let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
                    sections.append(
                        [
                            .levelValue(
                                title: "swap.total_fee".localized,
                                value: formatted,
                                level: .regular
                            ),
                        ]
                    )
                }
            }

            return sections
        }

        override func additionalFeeFields(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
            var fields = super.additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if swapQuote.affiliateFee > 0 {
                fields.append(
                    .value(
                        title: "swap.affiliate_fee".localized,
                        description: nil,
                        coinValue: CoinValue(kind: .token(token: tokenOut), value: swapQuote.affiliateFee),
                        currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: swapQuote.affiliateFee * $0) },
                        formatFull: true
                    )
                )
            }

            if swapQuote.liquidityFee > 0 {
                fields.append(
                    .value(
                        title: "swap.liquidity_fee".localized,
                        description: nil,
                        coinValue: CoinValue(kind: .token(token: tokenOut), value: swapQuote.liquidityFee),
                        currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: swapQuote.liquidityFee * $0) },
                        formatFull: true
                    )
                )
            }

            if swapQuote.outboundFee > 0 {
                fields.append(
                    .value(
                        title: "swap.outbound_fee".localized,
                        description: nil,
                        coinValue: CoinValue(kind: .token(token: tokenOut), value: swapQuote.outboundFee),
                        currencyValue: tokenOutRate.map {
                            CurrencyValue(currency: currency, value: swapQuote.outboundFee * $0)
                        },
                        formatFull: true
                    )
                )
            }

            return fields
        }
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
