import Foundation
import Combine
import MarketKit
import SwiftUI

protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var priority: Int { get }
    var initializedPublisher: AnyPublisher<Bool, Never> { get }
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote
    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote
    func otherSections(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) -> [SendDataSection]
    func settingsView(tokenIn: Token, tokenOut: Token, quote: IMultiSwapQuote, onChangeSettings: @escaping () -> Void) -> AnyView
    func settingView(settingId: String, tokenOut: Token, onChangeSetting: @escaping () -> Void) -> AnyView
    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView
    func swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, quote: IMultiSwapConfirmationQuote) async throws
}
