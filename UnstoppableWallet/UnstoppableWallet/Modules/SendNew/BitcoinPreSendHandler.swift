import BigInt
import BitcoinCore
import Combine
import Foundation
import MarketKit
import RxSwift
import SwiftUI

class BitcoinPreSendHandler {
    private let token: Token
    private let adapter: BitcoinBaseAdapter

    var sortType: TransactionDataSortType = .shuffle
    var rbfEnabled = true
    var pluginData = [UInt8: IPluginData]()
    var unspentOutputs: [UnspentOutputInfo]?

    private let balanceStateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceDataSubject = PassthroughSubject<BalanceData, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.adapter = adapter

        adapter.balanceStateUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] state in
                self?.balanceStateSubject.send(state)
            }
            .disposed(by: disposeBag)

        adapter.balanceDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] balanceData in
                self?.balanceDataSubject.send(balanceData)
            }
            .disposed(by: disposeBag)
    }
}

extension BitcoinPreSendHandler: IPreSendHandler {
    var hasMemo: Bool {
        true
    }

    var hasSettings: Bool {
        true
    }

    var balanceState: AdapterState {
        adapter.balanceState
    }

    var balanceStatePublisher: AnyPublisher<AdapterState, Never> {
        balanceStateSubject.eraseToAnyPublisher()
    }

    var balanceData: BalanceData {
        adapter.balanceData
    }

    var balanceDataPublisher: AnyPublisher<BalanceData, Never> {
        balanceDataSubject.eraseToAnyPublisher()
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
