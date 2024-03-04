import Foundation
import MarketKit
import SwiftUI

protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote
    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapConfirmationQuote
    func settingsView(tokenIn: Token, tokenOut: Token, onChangeSettings: @escaping () -> Void) -> AnyView
    func settingView(settingId: String) -> AnyView
    func preSwapView(stepId: String, tokenIn: Token, tokenOut: Token, amount: Decimal, isPresented: Binding<Bool>) -> AnyView
    func swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: IMultiSwapConfirmationQuote) async throws
}
