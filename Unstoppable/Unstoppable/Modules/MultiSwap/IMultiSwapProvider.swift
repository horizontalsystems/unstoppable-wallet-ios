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
    func mevProtectionAllowed(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote
    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote
    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool?
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

    func validateTrustedProvider(tokenIn _: Token, amountIn _: Decimal) async -> Bool? {
        if let result = Core.instance?.localStorage.debuggingAmlCheckResult {
            return result == .dirty ? false : nil
        }
        return true
    }

    func mevProtectionAllowed(tokenIn _: Token, tokenOut _: Token) -> Bool {
        false
    }
}

enum SwapProviderType: String, CaseIterable, Identifiable {
    case excellent
    case good
    case fair

    var title: String {
        rawValue.capitalized(with: .autoupdatingCurrent)
    }

    var icon: String {
        switch self {
        case .excellent: return "star_filled"
        case .good: return "shield_check_filled"
        case .fair: return "thumbsup"
        }
    }

    var сolorStyle: ColorStyle {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        }
    }

    var id: String {
        rawValue
    }
}
