import Combine
import Foundation
import SwiftUI

/// Funds a chain makes spendable through a step the user starts from a send or swap form, such as shielding
/// transparent ZEC, or by waiting for confirmations. The adapter's available balance already counts them; the
/// forms ask the step before their own amount checks and know only its button and screen. An instance is made
/// per form and wallet.
public protocol ISpendStepHandler {
    /// The step `amount` needs, or nil when the spendable balance covers it or the whole balance does not.
    func step(amount: Decimal) -> SpendStep?
    /// The screen the step's button opens, presented through the Coordinator.
    func view(isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView
    var updatedPublisher: AnyPublisher<Void, Never> { get }
}

public enum SpendStep: Equatable {
    case required(title: String)
    /// The form waits: a running step with its `progress` in 0...1, or confirmations with no progress to show.
    case pending(title: String, progress: Double?)
}

/// What the funds a form checks are about to be spent on; the step's button names it.
public enum SpendStepPurpose {
    case send
    case swap
}

class SpendStepHandler {
    init() {}

    /// nil when the chain has no such step for the wallet
    class func instance(wallet _: Wallet, purpose _: SpendStepPurpose) -> ISpendStepHandler? {
        nil
    }
}
