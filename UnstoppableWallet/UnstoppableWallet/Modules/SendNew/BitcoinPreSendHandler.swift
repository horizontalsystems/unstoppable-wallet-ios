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

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.adapter = adapter

        adapter.balanceStateUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] state in
                self?.stateSubject.send(state)
            }
            .disposed(by: disposeBag)

        adapter.balanceDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] balanceData in
                self?.balanceSubject.send(balanceData.available)
            }
            .disposed(by: disposeBag)
    }
}

extension BitcoinPreSendHandler: IPreSendHandler {
    var hasSettings: Bool {
        true
    }

    var state: AdapterState {
        adapter.balanceState
    }

    var statePublisher: AnyPublisher<AdapterState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balance: Decimal {
        adapter.balanceData.available
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    func hasMemo(address _: String?) -> Bool {
        true
    }

    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
            BitcoinSendSettingsView(handler: self, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        let params = SendParameters(
            address: address,
            value: adapter.convertToSatoshi(value: amount),
            sortType: sortType,
            rbfEnabled: rbfEnabled,
            memo: memo,
            unspentOutputs: unspentOutputs,
            pluginData: pluginData
        )

        return .valid(sendData: .bitcoin(token: token, params: params))
    }
}
