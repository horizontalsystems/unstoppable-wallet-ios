import Combine
import Foundation
import SwiftUI

public protocol IPreSendHandler {
    func title(_ code: String) -> String
    var hasSettings: Bool { get }
    var state: AdapterState { get }
    var statePublisher: AnyPublisher<AdapterState, Never> { get }
    var balance: Decimal { get }
    var balancePublisher: AnyPublisher<Decimal, Never> { get }
    var settingsModified: Bool { get }
    var settingsModifiedPublisher: AnyPublisher<Bool, Never> { get }
    func memoType(address: String?) -> MemoType
    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView
    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult
    /// Builds a transfer to a swap-provider deposit address (Private Send / Cross Pay). Recipient-only
    /// extras such as the Bitcoin time lock are never applied.
    func depositSendData(amount: Decimal, address: String, memo: String?) -> SendDataResult
    /// An immutable copy of the send settings that apply to a deposit transfer. Taken on the main
    /// thread, where the settings UI mutates this handler, so a deposit built later off the main
    /// thread never reads the live handler. Nil when the chain has no deposit-relevant settings.
    var depositSettingsSnapshot: PreSendSettingsSnapshot? { get }
    /// Same as `depositSendData(amount:address:memo:)`, but with the settings taken from `settings`
    /// instead of this handler's current state. Nil settings means the handler's defaults.
    func depositSendData(amount: Decimal, address: String, memo: String?, settings: PreSendSettingsSnapshot?) -> SendDataResult
    /// Chains whose payments carry a destination tag (XRP) show a fourth input; everyone else keeps it hidden.
    var destinationTagState: DestinationTagState { get }
    var destinationTagStatePublisher: AnyPublisher<DestinationTagState, Never> { get }
    func sendData(amount: Decimal, address: String, memo: String?, destinationTagInput: String) -> SendDataResult
    func set(address: String?)
}

/// What the destination tag input shows: nothing, an optional field, a field the destination
/// account insists on (`RequireDestTag`), or a value pinned by the pasted X-address.
public enum DestinationTagState: Equatable {
    case hidden
    case optional
    case required
    case fixed(UInt32)
}

public extension IPreSendHandler {
    func title(_ code: String) -> String {
        "send.title".localized(code)
    }

    var hasSettings: Bool {
        false
    }

    func memoType(address _: String?) -> MemoType {
        .none
    }

    func settingsView(onChangeSettings _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }

    var settingsModified: Bool {
        false
    }

    var destinationTagState: DestinationTagState {
        .hidden
    }

    var destinationTagStatePublisher: AnyPublisher<DestinationTagState, Never> {
        Empty().eraseToAnyPublisher()
    }

    func sendData(amount: Decimal, address: String, memo: String?, destinationTagInput _: String) -> SendDataResult {
        sendData(amount: amount, address: address, memo: memo)
    }

    func depositSendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        sendData(amount: amount, address: address, memo: memo)
    }

    var depositSettingsSnapshot: PreSendSettingsSnapshot? {
        nil
    }

    func depositSendData(amount: Decimal, address: String, memo: String?, settings _: PreSendSettingsSnapshot?) -> SendDataResult {
        depositSendData(amount: amount, address: address, memo: memo)
    }

    var settingsModifiedPublisher: AnyPublisher<Bool, Never> {
        Empty().eraseToAnyPublisher()
    }

    func set(address _: String?) {}
}

/// Chain-agnostic, immutable carrier for deposit-relevant send settings. Each chain with such
/// settings owns one optional payload; the rest leave everything nil.
public struct PreSendSettingsSnapshot: Sendable {
    let bitcoin: BitcoinDepositSettings?

    init(bitcoin: BitcoinDepositSettings? = nil) {
        self.bitcoin = bitcoin
    }
}

public enum SendDataResult {
    case valid(sendData: SendData)
    case invalid(cautions: [CautionNew])
}

public enum MemoType {
    case none
    case onChainPublic
    case onChainPrivate
    case local
}
