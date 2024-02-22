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

    override func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        let gasPrice = transactionSettings?.gasPrice

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount,
            gasPrice: gasPrice
        )

        var insufficientFeeBalance = false

        if let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit, let gasPrice {
            let evmBalance = evmKit.accountState?.balance ?? 0
            let txAmount = tokenIn.type.isNative ? amount : 0
            let feeAmount = BigUInt(quote.estimateGas * gasPrice.max)
            let totalAmount = txAmount + feeAmount

            insufficientFeeBalance = totalAmount > evmBalance
        }

        return await Quote(
            quote: quote,
            recipient: storage.value(for: MultiSwapSettingStorage.LegacySetting.address),
            slippage: storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default,
            insufficientFeeBalance: insufficientFeeBalance,
            gasPrice: gasPrice,
            nonce: transactionSettings?.nonce,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    override func swap(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, quote: IMultiSwapQuote) async throws {
        guard let quote = quote as? Quote else {
            throw SwapError.invalidQuote
        }

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        guard let gasPrice = quote.gasPrice else {
            throw SwapError.noGasPrice
        }

        guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

        let evmKit = evmKitWrapper.evmKit

        let swap = try await kit.swap(
            networkManager: networkManager,
            chain: evmKit.chain,
            receiveAddress: evmKit.receiveAddress,
            fromToken: address(token: tokenIn),
            toToken: address(token: tokenOut),
            amount: amount,
            slippage: quote.slippage,
            recipient: quote.recipient.flatMap { try? EvmKit.Address(hex: $0.raw) },
            gasPrice: gasPrice,
            gasLimit: quote.quote.estimateGas
        )

        let transactionData = TransactionData(to: swap.transaction.to, value: swap.transaction.value, input: swap.transaction.data)

        try await Task.sleep(nanoseconds: 2_000_000_000)

//        _ = try await evmKitWrapper.send(
//            transactionData: transactionData,
//            gasPrice: swap.transaction.gasPrice,
//            gasLimit: swap.transaction.gasLimit,
//            nonce: quote.nonce
//        )
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        try OneInchKit.Kit.routerAddress(chain: chain)
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
}

extension OneInchMultiSwapProvider {
    func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, blockchainType: tokenIn.blockchainType)
        let slippageViewModel = SlippageMultiSwapSettingsViewModel(storage: storage)
        let viewModel = BaseMultiSwapSettingsViewModel(fields: [addressViewModel, slippageViewModel])
        let view = ThemeNavigationView {
            RecipientAndSlippageMultiSwapSettingsView(
                viewModel: viewModel,
                addressViewModel: addressViewModel,
                slippageViewModel: slippageViewModel,
                onChangeSettings: onChangeSettings
            )
        }

        return AnyView(view)
    }

    func settingView(settingId: String) -> AnyView {
        switch settingId {
        default: return AnyView(EmptyView())
        }
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case invalidQuote
        case noGasPrice
        case noEvmKitWrapper
    }
}

extension OneInchMultiSwapProvider {
    class Quote: BaseEvmMultiSwapProvider.Quote {
        let quote: OneInchKit.Quote
        let recipient: Address?
        let slippage: Decimal
        let insufficientFeeBalance: Bool

        init(quote: OneInchKit.Quote, recipient: Address?, slippage: Decimal, insufficientFeeBalance: Bool, gasPrice: GasPrice?, nonce: Int?, allowanceState: AllowanceState) {
            self.quote = quote
            self.recipient = recipient
            self.slippage = slippage
            self.insufficientFeeBalance = insufficientFeeBalance

            super.init(gasPrice: gasPrice, gasLimit: quote.estimateGas, nonce: nonce, allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            quote.amountOut ?? 0
        }

        override var customButtonState: MultiSwapButtonState? {
            var customButtonState: MultiSwapButtonState?

            if insufficientFeeBalance {
                customButtonState = .init(title: "Insufficient Fee Balance", disabled: true)
            }

            return super.customButtonState ?? customButtonState
        }

        override var settingsModified: Bool {
            super.settingsModified || recipient != nil || slippage != MultiSwapSlippage.default
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

            switch MultiSwapSlippage.validate(slippage: slippage) {
            case .none: ()
            case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
            }

            return cautions
        }

        override func mainFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [MultiSwapMainField] {
            var fields = super.mainFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if let recipient {
                fields.append(
                    MultiSwapMainField(
                        title: "Recipient",
                        value: recipient.title,
                        valueLevel: .regular
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    MultiSwapMainField(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            return fields
        }

        override func confirmationPriceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [MultiSwapConfirmField] {
            var fields = super.confirmationPriceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if let recipient {
                fields.append(
                    .address(
                        title: "Recipient",
                        value: recipient.raw
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    .levelValue(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            let minAmountOut = amountOut * (1 - slippage / 100)

            fields.append(
                .value(
                    title: "Minimum Received",
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) }
                )
            )

            return fields
        }
    }
}
