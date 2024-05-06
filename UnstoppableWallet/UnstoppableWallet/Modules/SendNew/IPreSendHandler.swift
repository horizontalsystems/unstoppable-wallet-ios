import Combine
import Foundation
import SwiftUI

protocol IPreSendHandler {
    var hasMemo: Bool { get }
    var hasSettings: Bool { get }
    var balanceState: AdapterState { get }
    var balanceStatePublisher: AnyPublisher<AdapterState, Never> { get }
    var balanceData: BalanceData { get }
    var balanceDataPublisher: AnyPublisher<BalanceData, Never> { get }
    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView
    func sendData(amount: Decimal, address: String, memo: String?) -> SendData?
}

extension IPreSendHandler {
    var hasMemo: Bool {
        false
    }

    var hasSettings: Bool {
        false
    }

    func settingsView(onChangeSettings _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }
}
