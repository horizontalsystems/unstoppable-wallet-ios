import Combine
import Foundation
import SwiftUI

protocol IPreSendHandler {
    var hasSettings: Bool { get }
    var state: AdapterState { get }
    var statePublisher: AnyPublisher<AdapterState, Never> { get }
    var balance: Decimal { get }
    var balancePublisher: AnyPublisher<Decimal, Never> { get }
    func validate(address: String) -> Caution?
    func hasMemo(address: String?) -> Bool
    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView
    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult
}

extension IPreSendHandler {
    var hasSettings: Bool {
        false
    }

    func validate(address _: String) -> Caution? {
        nil
    }

    func hasMemo(address _: String?) -> Bool {
        false
    }

    func settingsView(onChangeSettings _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }
}

enum SendDataResult {
    case valid(sendData: SendData)
    case invalid(cautions: [CautionNew])
}
