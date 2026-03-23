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
    func validateTrustedProvider(tokenIn: Token) async -> Bool
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

    func validateTrustedProvider(tokenIn _: Token) async -> Bool {
        true
    }
}

enum SwapProviderType: String, CaseIterable, Identifiable {
    case auto
    case flexible
    case controlled
    case preCheck

    var title: String {
        rawValue.capitalized(with: .autoupdatingCurrent)
    }

    var icon: String {
        switch self {
        case .auto: return "shield_check_filled"
        case .flexible: return "thumbsup"
        case .controlled: return "warning_filled"
        case .preCheck: return "radar"
        }
    }

    var сolorStyle: ColorStyle {
        switch self {
        case .auto: return .green
        case .flexible: return .blue
        case .controlled: return .yellow
        case .preCheck: return .primary
        }
    }

    var id: String {
        rawValue
    }

    @ViewBuilder func body() -> some View {
        HStack(spacing: .margin4) {
            ThemeImage(icon, size: .iconSize16, colorStyle: сolorStyle)
            ThemeText(title, style: .captionSB, colorStyle: сolorStyle)
        }
    }
}
