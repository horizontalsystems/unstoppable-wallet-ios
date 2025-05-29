import Combine
import Foundation
import SwiftUI

protocol IPreSendHandler {
    func title(_ code: String) -> String
    var hasSettings: Bool { get }
    var state: AdapterState { get }
    var statePublisher: AnyPublisher<AdapterState, Never> { get }
    var balance: Decimal { get }
    var balancePublisher: AnyPublisher<Decimal, Never> { get }
    var settingsModified: Bool { get }
    var settingsModifiedPublisher: AnyPublisher<Bool, Never> { get }
    func hasMemo(address: String?) -> Bool
    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView
    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult
}

extension IPreSendHandler {
    func title(_ code: String) -> String {
        "send.title".localized(code)
    }

    var hasSettings: Bool {
        false
    }

    func hasMemo(address _: String?) -> Bool {
        false
    }

    func settingsView(onChangeSettings _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }

    var settingsModified: Bool {
        false
    }

    var settingsModifiedPublisher: AnyPublisher<Bool, Never> {
        Empty().eraseToAnyPublisher()
    }
}

enum SendDataResult {
    case valid(sendData: SendData)
    case invalid(cautions: [CautionNew])
}
