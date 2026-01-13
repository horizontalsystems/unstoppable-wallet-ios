import Combine
import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BaseEvmMultiSwapProvider: IMultiSwapProvider {
    private let adapterManager = Core.shared.adapterManager
    private let localStorage = Core.shared.localStorage
    let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let allowanceHelper = MultiSwapAllowanceHelper()

    var id: String { fatalError("Must be implemented in subclass") }
    var name: String { fatalError("Must be implemented in subclass") }
    var type: SwapProviderType { fatalError("Must be implemented in subclass") }
    var aml: Bool { true }
    var icon: String { fatalError("Must be implemented in subclass") }

    func supports(tokenIn _: Token, tokenOut _: Token) -> Bool {
        fatalError("Must be implemented in subclass")
    }

    func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> MultiSwapQuote {
        fatalError("Must be implemented in subclass")
    }

    func confirmationQuote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, slippage _: Decimal, recipient _: String?, transactionSettings _: TransactionSettings?) async throws -> ISwapFinalQuote {
        fatalError("Must be implemented in subclass")
    }

    func settingsView(tokenIn _: Token, tokenOut _: Token, quote _: MultiSwapQuote, onChangeSettings _: @escaping () -> Void) -> AnyView {
        fatalError("settingsView(tokenIn:tokenOut:onChangeSettings:) has not been implemented")
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
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
