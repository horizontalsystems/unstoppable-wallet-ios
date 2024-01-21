import Foundation
import MarketKit
import SwiftUI

protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote
    func view(settingId: String) -> AnyView
}

extension IMultiSwapProvider {
    func view(settingId: String) -> AnyView {
        AnyView(Text("Abc"))
    }
}