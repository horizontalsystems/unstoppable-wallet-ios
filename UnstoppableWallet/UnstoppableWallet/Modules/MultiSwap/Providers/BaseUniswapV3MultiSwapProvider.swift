import BigInt
import EvmKit
import Foundation
import MarketKit
import SwiftUI
import UniswapKit

class BaseUniswapV3MultiSwapProvider: BaseUniswapMultiSwapProvider {
    private let kit: UniswapKit.KitV3

    init(kit: UniswapKit.KitV3, storage: MultiSwapSettingStorage) {
        self.kit = kit

        super.init(storage: storage)
    }

    private func kitToken(chain: Chain, token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return try kit.etherToken(chain: chain)
        case let .eip20(address): return try kit.token(contractAddress: EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw SwapError.invalidToken
        }
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        kit.routerAddress(chain: chain)
    }

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let kitTokenIn = try kitToken(chain: chain, token: tokenIn)
        let kitTokenOut = try kitToken(chain: chain, token: tokenOut)

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.noHttpRpcSource
        }

        let recipient: Address? = storage.value(for: MultiSwapSettingStorage.LegacySetting.address)
        let slippage: Decimal = storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default

        let kitRecipient = try recipient.map { try EvmKit.Address(hex: $0.raw) }

        let tradeOptions = TradeOptions(
            allowedSlippage: slippage,
            ttl: TradeOptions.defaultTtl,
            recipient: kitRecipient,
            feeOnTransfer: false
        )

        let bestTrade = try await kit.bestTradeExactIn(rpcSource: rpcSource, chain: chain, tokenIn: kitTokenIn, tokenOut: kitTokenOut, amountIn: amountIn, options: tradeOptions)

        var estimatedGas: Int?

        if let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionSettings, case let .evm(gasPrice, _) = transactionSettings
        {
            do {
                let transactionData = try kit.transactionData(receiveAddress: evmKit.receiveAddress, chain: chain, bestTrade: bestTrade, tradeOptions: tradeOptions)
                estimatedGas = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
            } catch {}
        }

        return await Quote(
            bestTrade: bestTrade,
            recipient: recipient,
            slippage: slippage,
            estimatedGas: estimatedGas,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token) -> AnyView {
        let addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, blockchainType: tokenIn.blockchainType)
        let slippageViewModel = SlippageMultiSwapSettingsViewModel(storage: storage)
        let viewModel = BaseMultiSwapSettingsViewModel(fields: [addressViewModel, slippageViewModel])
        let view = ThemeNavigationView {
            RecipientAndSlippageMultiSwapSettingsView(
                viewModel: viewModel,
                addressViewModel: addressViewModel,
                slippageViewModel: slippageViewModel
            )
        }

        return AnyView(view)
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

extension BaseUniswapV3MultiSwapProvider {
    class Quote: BaseUniswapMultiSwapProvider.Quote {
        private let bestTrade: TradeDataV3

        init(bestTrade: TradeDataV3, recipient: Address?, slippage: Decimal, estimatedGas: Int?, allowanceState: AllowanceState) {
            self.bestTrade = bestTrade

            super.init(recipient: recipient, slippage: slippage, estimatedGas: estimatedGas, allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            bestTrade.amountOut ?? 0
        }
    }
}
