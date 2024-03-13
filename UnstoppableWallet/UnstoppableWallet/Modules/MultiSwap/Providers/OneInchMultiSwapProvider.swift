import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import OneInchKit
import SwiftUI

class OneInchMultiSwapProvider: BaseEvmMultiSwapProvider {
    private let kit: OneInchKit.Kit
    private let networkManager = App.shared.networkManager
    private let evmFeeEstimator = EvmFeeEstimator()

    init(kit: OneInchKit.Kit, storage: MultiSwapSettingStorage) {
        self.kit = kit

        super.init(storage: storage)
    }

    override var id: String {
        "1inch"
    }

    override var name: String {
        "1Inch"
    }

    override var icon: String {
        "1inch_32"
    }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom: return true
        default: return false
        }
    }

    override func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
    }

    override func confirmationQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let quote = try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let blockchainType = tokenIn.blockchainType
        let gasPrice = transactionSettings?.gasPrice
        var evmFeeData: EvmFeeData?
        var resolvedSwap: Swap?
        var insufficientFeeBalance = false

        if let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let gasPrice,
           let amount = rawAmount(amount: amountIn, token: tokenIn)
        {
            let swap = try await kit.swap(
                networkManager: networkManager,
                chain: evmKit.chain,
                receiveAddress: evmKit.receiveAddress,
                fromToken: address(token: tokenIn),
                toToken: address(token: tokenOut),
                amount: amount,
                slippage: slippage,
                recipient: recipient.flatMap { try? EvmKit.Address(hex: $0.raw) },
                gasPrice: gasPrice
            )

            resolvedSwap = swap

            let evmBalance = evmKit.accountState?.balance ?? 0
            let txAmount = tokenIn.type.isNative ? amount : 0
            let feeAmount = BigUInt(swap.transaction.gasLimit * gasPrice.max)
            let totalAmount = txAmount + feeAmount

            insufficientFeeBalance = totalAmount > evmBalance

            evmFeeData = try await evmFeeEstimator.oneIncheEstimateFee(blockchainType: blockchainType, evmKit: evmKit, swap: swap, gasPrice: gasPrice)
        }

        return ConfirmationQuote(
            quote: quote,
            swap: resolvedSwap,
            insufficientFeeBalance: insufficientFeeBalance,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    override func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
            RecipientAndSlippageMultiSwapSettingsView(tokenIn: tokenIn, storage: storage, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    override func swap(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        guard let quote = quote as? ConfirmationQuote else {
            throw SwapError.invalidQuote
        }

        guard let swap = quote.swap else {
            throw SwapError.invalidSwap
        }

        guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

        _ = try await evmKitWrapper.send(
            transactionData: TransactionData(to: swap.transaction.to, value: swap.transaction.value, input: swap.transaction.data),
            gasPrice: swap.transaction.gasPrice,
            gasLimit: swap.transaction.gasLimit,
            nonce: quote.nonce
        )
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        try OneInchKit.Kit.routerAddress(chain: chain)
    }

    private func internalQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> Quote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount
        )

        return await Quote(
            quote: quote,
            recipient: recipient,
            slippage: slippage,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    private func address(token: MarketKit.Token) throws -> EvmKit.Address {
        switch token.type {
        case .native: return try EvmKit.Address(hex: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        case let .eip20(address): return try EvmKit.Address(hex: address)
        default: throw SwapError.invalidAddress
        }
    }

    private func rawAmount(amount: Decimal, token: MarketKit.Token) -> BigUInt? {
        let rawAmountString = (amount * pow(10, token.decimals)).hs.roundedString(decimal: 0)
        return BigUInt(rawAmountString)
    }

    private var recipient: Address? {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.address)
    }

    private var slippage: Decimal {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case invalidQuote
        case invalidSwap
        case noEvmKitWrapper
    }
}

extension OneInchMultiSwapProvider {
    class Quote: BaseEvmMultiSwapProvider.Quote {
        let quote: OneInchKit.Quote
        let recipient: Address?
        let slippage: Decimal

        init(quote: OneInchKit.Quote, recipient: Address?, slippage: Decimal, allowanceState: AllowanceState) {
            self.quote = quote
            self.recipient = recipient
            self.slippage = slippage

            super.init(allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            quote.amountOut ?? 0
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

    class ConfirmationQuote: BaseEvmMultiSwapProvider.ConfirmationQuote {
        let quote: Quote
        let swap: Swap?
        let insufficientFeeBalance: Bool

        init(quote: Quote, swap: Swap?, insufficientFeeBalance: Bool, evmFeeData: EvmFeeData?, nonce: Int?) {
            self.quote = quote
            self.swap = swap
            self.insufficientFeeBalance = insufficientFeeBalance

            super.init(gasPrice: swap?.transaction.gasPrice, evmFeeData: evmFeeData, nonce: nonce)
        }

        override var amountOut: Decimal {
            swap?.amountOut ?? quote.quote.amountOut ?? 0
        }

        override var canSwap: Bool {
            super.canSwap && swap != nil && !insufficientFeeBalance
        }

        override func cautions(feeToken: MarketKit.Token?) -> [CautionNew] {
            var cautions = super.cautions(feeToken: feeToken)

            if insufficientFeeBalance {
                cautions.append(
                    .init(
                        title: "fee_settings.errors.insufficient_balance".localized,
                        text: "ethereum_transaction.error.insufficient_balance_with_fee".localized(feeToken?.coin.code ?? ""),
                        type: .error
                    )
                )
            }

            cautions.append(contentsOf: quote.cautions())

            return cautions
        }

        override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
            var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if let recipient = quote.recipient {
                fields.append(
                    .address(
                        title: "swap.recipient".localized,
                        value: recipient.title
                    )
                )
            }

            let slippage = quote.slippage

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    .levelValue(
                        title: "swap.slippage".localized,
                        value: "\(slippage.description)%",
                        level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            let minAmountOut = amountOut * (1 - slippage / 100)

            fields.append(
                .value(
                    title: "swap.confirmation.minimum_received".localized,
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) },
                    formatFull: true
                )
            )

            return fields
        }
    }
}
