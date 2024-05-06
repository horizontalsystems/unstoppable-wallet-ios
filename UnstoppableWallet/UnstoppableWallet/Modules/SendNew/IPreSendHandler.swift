import Foundation
import SwiftUI

protocol IPreSendHandler {
    var hasSettings: Bool { get }
    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView
    func sendData(amount: Decimal, address: String, memo: String?) -> SendData?
}

extension IPreSendHandler {
    var hasSettings: Bool {
        false
    }

    func settingsView(onChangeSettings _: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }
}
