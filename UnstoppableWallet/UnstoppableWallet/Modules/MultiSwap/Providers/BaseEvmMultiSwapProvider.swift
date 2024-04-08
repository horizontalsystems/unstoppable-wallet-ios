import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BaseEvmMultiSwapProvider: IMultiSwapProvider {
    private let adapterManager = App.shared.adapterManager
    let evmBlockchainManager = App.shared.evmBlockchainManager
    let storage: MultiSwapSettingStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    var id: String {
        fatalError("Must be implemented in subclass")
    }

    var name: String {
        fatalError("Must be implemented in subclass")
    }

    var icon: String {
        fatalError("Must be implemented in subclass")
    }

    func supports(tokenIn _: Token, tokenOut _: Token) -> Bool {
        fatalError("Must be implemented in subclass")
    }

    func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> IMultiSwapQuote {
        fatalError("Must be implemented in subclass")
    }

    func confirmationQuote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        fatalError("Must be implemented in subclass")
    }

    func settingsView(tokenIn _: Token, tokenOut _: Token, onChangeSettings _: @escaping () -> Void) -> AnyView {
        fatalError("settingsView(tokenIn:tokenOut:onChangeSettings:) has not been implemented")
    }

    func settingView(settingId _: String) -> AnyView {
        fatalError("settingView(settingId:) has not been implemented")
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, quote _: IMultiSwapConfirmationQuote) async throws {
        fatalError("Must be implemented in subclass")
    }

    func spenderAddress(chain _: Chain) throws -> EvmKit.Address {
        fatalError("Must be implemented in subclass")
    }

    func allowanceState(token: Token, amount: Decimal) async -> MultiSwapAllowanceHelper.AllowanceState {
        do {
            let chain = evmBlockchainManager.chain(blockchainType: token.blockchainType)
            let spenderAddress = try spenderAddress(chain: chain)

            return await allowanceHelper.allowanceState(spenderAddress: spenderAddress, token: token, amount: amount)
        } catch {
            return .unknown
        }
    }
}
