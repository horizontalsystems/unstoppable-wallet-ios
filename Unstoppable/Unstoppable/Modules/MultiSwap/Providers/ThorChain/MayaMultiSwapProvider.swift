import Alamofire
import BitcoinCore
import Foundation
import MarketKit
import ObjectMapper
import SwiftUI
import ZcashLightClientKit

class MayaMultiSwapProvider: BaseThorChainMultiSwapProvider {
    static let id = "MAYACHAIN"
    static let name = "Maya Protocol"

    private let testNetManager = Core.shared.testNetManager
    private var temporaryDestinationAddresses = [BlockchainType: String]()

    override var baseUrl: String {
        let stagenet = testNetManager.mayaStagenetEnabled ? "stagenet." : ""
        return "https://\(stagenet)mayanode.mayachain.info/mayachain"
    }

    override var id: String { Self.id }
    override var name: String { Self.name }
    override var type: SwapProviderType { .auto }
    override var icon: String { "swap_provider_maya" }

    override var affiliate: String? {
        AppConfig.mayaAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.mayaAffiliateBps
    }

    private func zcashSwapQuote(adapter: ZcashAdapter, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal) async throws -> SwapQuote {
        let refundAddress = try await resolveDestination(recipient: nil, token: tokenIn)
        var params = Parameters()

        // add refund_address for automatic request full memo field. Avoid issue with long memo using from_address=your unified_address

        guard let fromAddress = adapter.uAddress?.stringEncoded else {
            throw SendTransactionError.invalidAddress
        }

        params["from_address"] = fromAddress
        params["refund_address"] = refundAddress

        let swapQuote = try await super.swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, params: params)

        let unifiedAddress = try await inboundUnifiedAddress(tokenIn: tokenIn)

        return SwapQuote(quote: swapQuote, unifiedAddress: unifiedAddress)
    }

    private func proposal(adapter: ZcashAdapter, tokenIn _: Token, swapQuote: SwapQuote, amountIn: Decimal) async throws -> Proposal {
        guard let tRecipient = adapter.recipient(from: swapQuote.quote.inboundAddress),
              let uRecipient = adapter.recipient(from: swapQuote.unifiedAddress)
        else {
            throw SendTransactionError.invalidAddress
        }

        let transparentOutput = ZcashAdapter.TransferOutput(amount: amountIn.rounded(decimal: 8), address: tRecipient, memo: nil)
        let memoOutput = try ZcashAdapter.TransferOutput(
            amount: 0,
            address: uRecipient,
            memo: .init(string: swapQuote.quote.memo)
        )

        return try await adapter.sendProposal(outputs: [transparentOutput, memoOutput])
    }

    override func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote {
        // use base scenario for all tokens except zcash
        guard tokenIn.blockchainType == .zcash else {
            return try await super.confirmationQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, recipient: recipient, transactionSettings: transactionSettings)
        }

        guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
            throw SwapError.noAdapter
        }

        let swapQuote = try await zcashSwapQuote(adapter: adapter, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage)

        var transactionError: Error?

        var result: Proposal?
        do {
            result = try await proposal(adapter: adapter, tokenIn: tokenIn, swapQuote: swapQuote, amountIn: amountIn)
        } catch {
            transactionError = error
        }

        if let dustThreshold = swapQuote.quote.dustThreshold,
           Int(Zatoshi.from(decimal: amountIn).amount) <= dustThreshold
        {
            transactionError = BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
        }

        return ZcashSwapFinalQuote(
            expectedBuyAmount: swapQuote.quote.expectedAmountOut,
            proposal: result,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: swapQuote.quote.totalSwapSeconds,
            transactionError: transactionError,
            fee: result?.totalFeeRequired().decimalValue.decimalValue,
            toAddress: adapter.receiveAddress.address
        )
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

    // override func settingsView(tokenOut: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
    //     let view = super.settingsView(tokenOut: tokenOut, onChangeSettings: onChangeSettings)
    //         .environment(\.addressParserFilter, .zCashTransparentOnly)
    //     return AnyView(view)
    // }

    override func resolveDestination(recipient: String?, token: Token) async throws -> String {
        if let recipient {
            return recipient
        }
        // use temporary address, to avoid muptiply create address without existing Adapter for token
        let temporaryDestination = temporaryDestinationAddresses[token.blockchainType].map { DestinationHelper.Destination(address: $0, type: .nonExisting) }
        let destination = try await DestinationHelper.resolveDestination(token: token, temporary: temporaryDestination)

        // if token not enabled, just save first address to avoid repeatly getter.
        if destination.type == .nonExisting {
            temporaryDestinationAddresses[token.blockchainType] = destination.address
        }

        return destination.address
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
