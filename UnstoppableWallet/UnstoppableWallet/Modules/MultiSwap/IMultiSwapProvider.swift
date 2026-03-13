import Combine
import Foundation
import MarketKit
import SwiftUI

protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var type: SwapProviderType { get }
    var requireTerms: Bool { get }
    var icon: String { get }
    var syncPublisher: AnyPublisher<Void, Never>? { get }
    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote
    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote
    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView
    func track(swap: Swap) async throws -> Swap
}

extension IMultiSwapProvider {
    var requireTerms: Bool {
        false
    }

    var syncPublisher: AnyPublisher<Void, Never>? {
        nil
    }

    func slippageSupported(tokenIn _: Token, tokenOut _: Token) -> Bool {
        true
    }
}

enum SwapProviderType: String, CaseIterable, Identifiable {
    case auto
    case flexible
    case controlled

    var title: String {
        let text = rawValue.capitalized(with: .autoupdatingCurrent)
        var icon: String?

//        switch self {
//        case .auto: icon = "😎"
//        case .flexible: icon = "🙂"
//        case .controlled: icon = "🥶"
//        }
            
        return [text, icon].compactMap { $0 }.joined()
    }

    var id: String {
        rawValue
    }

    var colorStyle: ColorStyle {
        switch self {
        case .auto:
            return .green
        case .flexible:
            return .blue
        case .controlled:
            return .yellow
        }
    }
}
