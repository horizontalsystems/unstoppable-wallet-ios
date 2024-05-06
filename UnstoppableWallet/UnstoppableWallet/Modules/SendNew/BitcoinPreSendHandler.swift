import BigInt
import BitcoinCore
import Foundation
import MarketKit
import SwiftUI

class BitcoinPreSendHandler {
    private let token: Token
    private let adapter: BitcoinBaseAdapter

    var sortType: TransactionDataSortType = .shuffle
    var rbfEnabled = true
    var pluginData = [UInt8: IPluginData]()
    var unspentOutputs: [UnspentOutputInfo]?

    init(token: Token, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.adapter = adapter
    }
}

extension BitcoinPreSendHandler: IPreSendHandler {
    var hasSettings: Bool {
        true
    }

    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
            BitcoinSendSettingsView(handler: self, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendData? {
        let params = SendParameters(
            address: address,
            value: adapter.convertToSatoshi(value: amount),
            sortType: sortType,
            rbfEnabled: rbfEnabled,
            memo: memo,
            unspentOutputs: unspentOutputs,
            pluginData: pluginData
        )

        return .bitcoin(token: token, params: params)
    }
}
