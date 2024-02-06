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

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        try OneInchKit.Kit.routerAddress(chain: chain)
    }
}

extension OneInchMultiSwapProvider: IMultiSwapProvider {
    var id: String {
        "1inch"
    }

    var name: String {
        "1Inch"
    }

    var icon: String {
        "1inch_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom: return true
        default: return false
        }
    }

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        guard let transactionSettings, case let .evm(gasPrice, _) = transactionSettings else {
            throw SwapError.noFeeData
        }

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount,
            gasPrice: gasPrice
        )

        return await Quote(
            quote: quote,
            tokenOut: tokenOut,
            recipient: storage.value(for: MultiSwapSettingStorage.LegacySetting.address),
            slippage: storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token) -> AnyView {
        let addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, blockchainType: tokenIn.blockchainType)
        let slippageViewModel = SlippageMultiSwapSettingsViewModel(storage: storage)
        let viewModel = BaseMultiSwapSettingsViewModel(fields: [addressViewModel, slippageViewModel])
        let view = ThemeNavigationView {
            OneInchMultiSwapSettingsView(
                viewModel: viewModel,
                addressViewModel: addressViewModel,
                slippageViewModel: slippageViewModel
            )
        }

        return AnyView(view)
    }

    func settingView(settingId: String) -> AnyView {
        switch settingId {
        default: return AnyView(EmptyView())
        }
    }

    func swap(quote: IMultiSwapQuote, transactionSettings: MultiSwapTransactionSettings?) async throws {
        guard let quote = quote as? Quote else {
            throw SwapError.invalidQuote
        }

        print(String(describing: quote))
        print(String(describing: transactionSettings))

        try await Task.sleep(nanoseconds: 3_000_000_000)
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case noFeeData
        case invalidQuote
    }
}

extension OneInchMultiSwapProvider {
    class Quote: BaseEvmMultiSwapProvider.Quote {
        private let quote: OneInchKit.Quote
        private let tokenOut: MarketKit.Token
        private let recipient: Address?
        private let slippage: Decimal

        init(quote: OneInchKit.Quote, tokenOut: MarketKit.Token, recipient: Address?, slippage: Decimal, allowanceState: AllowanceState) {
            self.quote = quote
            self.tokenOut = tokenOut
            self.recipient = recipient
            self.slippage = slippage

            super.init(estimatedGas: quote.estimateGas, allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            quote.amountOut ?? 0
        }

        override var mainFields: [MultiSwapMainField] {
            var fields = super.mainFields

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
                        valueLevel: .warning // get level from slippage value
                    )
                )
            }

            return fields
        }

        override var cautions: [CautionNew] {
            var cautions = super.cautions

            // append slippage cautions here

            return cautions
        }

        override var confirmFieldSections: [[MultiSwapConfirmField]] {
            var sections = super.confirmFieldSections

            let minAmountOut = amountOut * (1 - slippage / 100)

            sections.append(
                [
                    .value(
                        title: "Minimum Received",
                        description: nil,
                        coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                        currencyValue: nil
                    ),
                ]
            )

            return sections
        }
    }
}
