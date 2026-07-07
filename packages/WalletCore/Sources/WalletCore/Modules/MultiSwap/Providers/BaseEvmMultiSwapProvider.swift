import Combine
import EvmKit
import Foundation
import MarketKit
import SwiftUI

public class BaseEvmMultiSwapProvider: IMultiSwapProvider {
    private let adapterManager = Core.shared.adapterManager
    private let localStorage = Core.shared.localStorage
    let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let allowanceHelper = MultiSwapAllowanceHelper()

    public var id: String { fatalError("Must be implemented in subclass") }
    public var name: String { fatalError("Must be implemented in subclass") }
    public var type: SwapProviderType { fatalError("Must be implemented in subclass") }
    public var icon: String { fatalError("Must be implemented in subclass") }
    public var requireTerms: Bool { false }
    public var syncPublisher: AnyPublisher<Void, Never>? { nil }

    public func slippageSupported(tokenIn _: Token, tokenOut _: Token) -> Bool {
        true
    }

    public func supports(tokenIn _: Token, tokenOut _: Token) -> Bool {
        fatalError("Must be implemented in subclass")
    }

    public func mevProtectionAllowed(tokenIn: Token, tokenOut: Token) -> Bool {
        MerkleTransactionAdapter.allowProtection(blockchainTypeIn: tokenIn.blockchainType, blockchainTypeOut: tokenOut.blockchainType)
    }

    public func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> MultiSwapQuote {
        fatalError("Must be implemented in subclass")
    }

    public func confirmationQuote(multiSwapQuote _: MultiSwapQuote, tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, slippage _: Decimal, recipient _: String?, transactionSettings _: TransactionSettings?) async throws -> SwapFinalQuote {
        fatalError("Must be implemented in subclass")
    }

    public func validateTrustedProvider(tokenIn _: Token, amountIn _: Decimal) async throws -> Bool? {
        if let result = Core.instance?.localStorage.debuggingAmlCheckResult {
            return result == .dirty ? false : nil
        }
        return true
    }

    func settingsView(tokenIn _: Token, tokenOut _: Token, quote _: MultiSwapQuote, onChangeSettings _: @escaping () -> Void) -> AnyView {
        fatalError("settingsView(tokenIn:tokenOut:onChangeSettings:) has not been implemented")
    }

    public func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    public func track(swap _: Swap) async throws -> Swap {
        fatalError("Must be implemented in subclass")
    }

    func spenderAddress(chain _: Chain) throws -> EvmKit.Address {
        fatalError("Must be implemented in subclass")
    }

    func allowanceState(token: Token, amount: Decimal) async -> MultiSwapAllowanceHelper.AllowanceState {
        do {
            let chain = try evmBlockchainManager.chain(blockchainType: token.blockchainType)
            let spenderAddress = try spenderAddress(chain: chain)

            return await allowanceHelper.allowanceState(spenderAddress: .init(raw: spenderAddress.eip55), token: token, amount: amount)
        } catch {
            return .unknown
        }
    }
}

extension BaseEvmMultiSwapProvider {
    static func validateBalance(evmKitWrapper: EvmKitWrapper, transactionData: TransactionData, evmFeeData: EvmFeeData, gasPriceData: GasPriceData) throws {
        let evmBalance = evmKitWrapper.evmKit.accountState?.balance ?? 0
        let txAmount = transactionData.value
        let feeAmount = evmFeeData.totalFee(gasPrice: gasPriceData.userDefined)

        if txAmount + feeAmount > evmBalance {
            throw AppError.ethereum(reason: .insufficientBalanceWithFee)
        }
    }
}
