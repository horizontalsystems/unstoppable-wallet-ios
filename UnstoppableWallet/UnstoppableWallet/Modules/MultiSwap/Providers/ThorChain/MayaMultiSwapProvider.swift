import BitcoinCore
import Foundation
import MarketKit
import ObjectMapper
import SwiftUI
import ZcashLightClientKit

class MayaMultiSwapProvider: BaseThorChainMultiSwapProvider {
    private let testNetManager = Core.shared.testNetManager

    override var baseUrl: String {
        let stagenet = testNetManager.mayaStagenetEnabled ? "stagenet." : ""
        return "https://\(stagenet)mayanode.mayachain.info/mayachain"
    }

    override var id: String {
        "mayachain"
    }

    override var name: String {
        "Maya Protocol"
    }

    override var icon: String {
        "maya_32"
    }

    override var affiliate: String? {
        AppConfig.mayaAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.mayaAffiliateBps
    }

    private func zcashSwapQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal? = nil) async throws -> SwapQuote {
        let swapQuote = try await super.swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage)

        let unifiedAddress = try await inboundUnifiedAddress(tokenIn: tokenIn)
        return SwapQuote(quote: swapQuote, unifiedAddress: unifiedAddress)
    }

    private func proposal(tokenIn: Token, swapQuote: SwapQuote, amountIn: Decimal) async throws -> Proposal {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter,
              let tAddress = adapter.tAddress?.stringEncoded
        else {
            throw SwapError.noZcashAdapter
        }

        guard let tRecipient = adapter.recipient(from: swapQuote.quote.inboundAddress),
              let uRecipient = adapter.recipient(from: swapQuote.unifiedAddress)
        else {
            throw SendTransactionError.invalidAddress
        }

        let transparentOutput = ZcashAdapter.TransferOutput(amount: amountIn, address: tRecipient, memo: nil)
        let memoOutput = try ZcashAdapter.TransferOutput(
            amount: 0,
            address: uRecipient,
            memo: .init(string: swapQuote.memo(refundAddress: tAddress))
        )
        return try await adapter.sendProposal(outputs: [transparentOutput, memoOutput])
    }

    override func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        // use base scenario for all tokens except zcash
        guard tokenIn.blockchainType == .zcash else {
            return try await super.confirmationQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, transactionSettings: transactionSettings)
        }

        let swapQuote = try await zcashSwapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        let slippage = storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default

        var transactionError: Error?
        let proposal = try await proposal(tokenIn: tokenIn, swapQuote: swapQuote, amountIn: amountIn)

        if let dustThreshold = swapQuote.quote.dustThreshold,
           Int(Zatoshi.from(decimal: amountIn).amount) <= dustThreshold
        {
            transactionError = BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
        }

        return MayaMultiSwapZcashConfirmationQuote(
            swapQuote: swapQuote,
            recipient: storage.recipient(blockchainType: tokenIn.blockchainType),
            amountIn: amountIn,
            totalFeeRequired: proposal.totalFeeRequired(),
            slippage: slippage,
            transactionError: transactionError
        )
    }

    override func swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        if let quote = quote as? MayaMultiSwapZcashConfirmationQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
                throw SwapError.noZcashAdapter
            }
            let proposal = try await proposal(tokenIn: tokenIn, swapQuote: quote.swapQuote, amountIn: amountIn)
            try await adapter.send(proposal: proposal)
        } else {
            try await super.swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, quote: quote)
        }
    }

    private func inboundUnifiedAddress(tokenIn: Token) async throws -> String {
        let json = try await networkManager.fetchJson(url: "\(baseUrl)/inbound_addresses")

        guard let jsonArray = json as? [[String: Any]] else {
            throw MayaProviderError.noShieldedAddress
        }

        if let zecChain = jsonArray.first(where: { ($0["chain"] as? String) == tokenIn.coin.code.uppercased() }),
           let shieldedConfig = zecChain["shielded_memo_config"] as? [String: Any],
           let unifiedAddress = shieldedConfig["unified_address"] as? String
        {
            return unifiedAddress
        }

        throw MayaProviderError.noShieldedAddress
    }

    override func settingsView(tokenOut: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = super.settingsView(tokenOut: tokenOut, onChangeSettings: onChangeSettings)
            .environment(\.addressParserFilter, .zCashTransparentOnly)
        return AnyView(view)
    }
}

extension MayaMultiSwapProvider {
    struct SwapQuote {
        let unifiedAddress: String
        let quote: BaseThorChainMultiSwapProvider.SwapQuote

        init(quote: BaseThorChainMultiSwapProvider.SwapQuote, unifiedAddress: String) {
            self.unifiedAddress = unifiedAddress
            self.quote = quote
        }

        func memo(refundAddress: String) -> String {
            // example: "=:ARB.USDT:0xA73339e3bE3bd4B3fDC7e4094c1417135544bE07:0/1/0"
            var memoParts = quote.memo.split(separator: ":")
            guard memoParts.count >= 3 else {
                return quote.memo
            }
            memoParts[2] += "/\(refundAddress)"

            let joined = memoParts.joined(separator: ":")
            return joined
        }
    }
}

extension MayaMultiSwapProvider {
    enum MayaProviderError: Error, LocalizedError {
        case noShieldedAddress

        public var errorDescription: String? {
            switch self {
            case .noShieldedAddress: return "swap.maya.shielded_address.error".localized
            }
        }
    }
}
