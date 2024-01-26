import Foundation
import MarketKit
import SwiftUI

protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapQuote
    func settingsView(tokenIn: Token, tokenOut: Token) -> AnyView
    func settingView(settingId: String) -> AnyView
    func swap(quote: IMultiSwapQuote, transactionSettings: MultiSwapTransactionSettings?) async throws
}

extension IMultiSwapProvider {
    func settingsView(tokenIn _: Token, tokenOut _: Token) -> AnyView {
        AnyView(Text("Settings View"))
    }

    func settingView(settingId: String) -> AnyView {
        AnyView(Text("Setting View: \(settingId)"))
    }
}
