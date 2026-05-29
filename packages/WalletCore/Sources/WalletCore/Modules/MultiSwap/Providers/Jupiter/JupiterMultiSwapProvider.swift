import Foundation
import MarketKit
import SolanaKit
import SwiftUI

class JupiterMultiSwapProvider: IMultiSwapProvider {
    static let id = "jupiter"
    static let name = "Jupiter"

    private let adapterManager = Core.shared.adapterManager
    private let solanaKitManager = Core.shared.solanaKitManager

    var id: String { Self.id }
    var name: String { Self.name }
    var type: SwapProviderType { .auto }
    var aml: Bool { false }
    var icon: String { "swap_provider_jupiter" }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        guard tokenIn.blockchainType == .solana, tokenOut.blockchainType == .solana else {
            return false
        }

        switch tokenIn.type {
        case .native, .spl: break
        default: return false
        }

        switch tokenOut.type {
        case .native, .spl: break
        default: return false
        }

        return true
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        guard let kit = solanaKitManager.solanaKit else {
            throw SwapError.noSolanaKit
        }

        guard let inputMint = mintAddress(token: tokenIn),
              let outputMint = mintAddress(token: tokenOut)
        else {
            throw SwapError.invalidMint
        }

        guard let amount = rawAmount(amountIn, decimals: tokenIn.decimals) else {
            throw SwapError.invalidAmount
        }

        let quoteResponse = try await kit.jupiterQuote(
            inputMint: inputMint,
            outputMint: outputMint,
            amount: amount,
            slippageBps: 100 // default 1%
        )

        guard let expectedAmountOut = decimalAmount(quoteResponse.outAmount, decimals: tokenOut.decimals) else {
            throw SwapError.invalidAmount
        }

        return MultiSwapQuote(expectedBuyAmount: expectedAmountOut)
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings _: TransactionSettings?) async throws -> SwapFinalQuote {
        guard let kit = solanaKitManager.solanaKit else {
            throw SwapError.noSolanaKit
        }

        guard let inputMint = mintAddress(token: tokenIn),
              let outputMint = mintAddress(token: tokenOut)
        else {
            throw SwapError.invalidMint
        }

        guard let amount = rawAmount(amountIn, decimals: tokenIn.decimals) else {
            throw SwapError.invalidAmount
        }

        let slippageBps = NSDecimalNumber(decimal: slippage * 100).intValue

        let quoteResponse = try await kit.jupiterQuote(
            inputMint: inputMint,
            outputMint: outputMint,
            amount: amount,
            slippageBps: slippageBps
        )

        guard let expectedAmountOut = decimalAmount(quoteResponse.outAmount, decimals: tokenOut.decimals) else {
            throw SwapError.invalidAmount
        }

        let swapResponse = try await kit.jupiterSwapTransaction(quoteResponse: quoteResponse, prioritizationMaxLamports: nil)

        guard let rawTransaction = Data(base64Encoded: swapResponse.swapTransaction) else {
            throw SwapError.invalidSwapTransaction
        }

        guard let adapter = adapterManager.adapter(for: tokenIn) as? ISendSolanaAdapter & IBalanceAdapter else {
            throw SwapError.noSolanaAdapter
        }

        var transactionError: Error?
        var fee: Decimal?

        do {
            let estimatedFee = try adapter.estimateFee(rawTransaction: rawTransaction)
            fee = estimatedFee

            let totalRequired = (tokenIn.type.isNative ? amountIn : 0) + estimatedFee
            if adapter.balanceData.available < totalRequired {
                throw SolanaSendHandler.TransactionError.insufficientSolBalance(balance: adapter.balanceData.available)
            }
        } catch {
            transactionError = error
        }

        return SolanaSwapFinalQuote(
            rawTransaction: rawTransaction,
            expectedAmountOut: expectedAmountOut,
            recipient: recipient,
            slippage: slippage,
            fee: fee,
            transactionError: transactionError,
            toAddress: kit.address,
            depositAddress: nil,
            providerSwapId: Self.id,
        )
    }

    func preSwapView(step _: MultiSwapPreSwapStep, tokenIn _: Token, tokenOut _: Token, amount _: Decimal, isPresented _: Binding<Bool>, onSuccess _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }

    func track(swap: Swap) async throws -> Swap {
        // TODO: Jupiter doesn't expose a swap-tracking API; return swap unchanged for now
        swap
    }
}

// MARK: - Helpers

private extension JupiterMultiSwapProvider {
    func mintAddress(token: Token) -> String? {
        switch token.type {
        case .native: return "So11111111111111111111111111111111111111112"
        case let .spl(address): return address
        default: return nil
        }
    }

    func rawAmount(_ amount: Decimal, decimals: Int) -> UInt64? {
        guard amount >= 0 else { return nil }
        let scaled = amount * pow(10, decimals)
        return NSDecimalNumber(decimal: scaled).uint64Value
    }

    func decimalAmount(_ rawString: String, decimals: Int) -> Decimal? {
        guard let raw = Decimal(string: rawString) else { return nil }
        return raw / pow(10, decimals)
    }
}

// MARK: - Errors

extension JupiterMultiSwapProvider {
    enum SwapError: Error {
        case noSolanaKit
        case noSolanaAdapter
        case invalidMint
        case invalidAmount
        case invalidSwapTransaction
    }
}
