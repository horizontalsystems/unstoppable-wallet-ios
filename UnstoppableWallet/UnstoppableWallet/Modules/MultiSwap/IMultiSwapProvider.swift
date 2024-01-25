import Foundation
import MarketKit
import SwiftUI

protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapQuote
    func settingsView(quote: IMultiSwapQuote) -> AnyView
    func settingView(settingId: String) -> AnyView
}

extension IMultiSwapProvider {
    func settingsView(quote: IMultiSwapQuote) -> AnyView {
        AnyView(Text(String(describing: quote)))
    }

    func settingView(settingId: String) -> AnyView {
        AnyView(Text("Setting View: \(settingId)"))
    }
}
