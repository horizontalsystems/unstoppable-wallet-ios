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
    /// Chains whose payments carry a destination tag (XRP) show a fourth input; everyone else keeps it hidden.
    var destinationTagState: DestinationTagState { get }
    var destinationTagStatePublisher: AnyPublisher<DestinationTagState, Never> { get }
    func sendData(amount: Decimal, address: String, memo: String?, destinationTagInput: String) -> SendDataResult
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

    var settingsModifiedPublisher: AnyPublisher<Bool, Never> {
        Empty().eraseToAnyPublisher()
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
