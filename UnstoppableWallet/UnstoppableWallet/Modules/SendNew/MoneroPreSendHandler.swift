import Combine
import Foundation
import MarketKit
import MoneroKit
import RxSwift
import SwiftUI

class MoneroPreSendHandler {
    private let token: Token
    private let adapter: MoneroAdapter

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: MoneroAdapter) {
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

extension MoneroPreSendHandler: IPreSendHandler {
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
        false
    }

    func sendData(amount: Decimal, address: String, memo _: String?) -> SendDataResult {
        if !MoneroKit.Kit.isValid(address: address, networkType: MoneroAdapter.networkType) {
            return .invalid(cautions: [CautionNew(text: "send.address.invalid_address".localized, type: .error)])
        }

        let moneroAmount: MoneroSendAmount
        if amount == adapter.balanceData.available {
            moneroAmount = .all(amount)
        } else {
            moneroAmount = .value(amount)
        }

        return .valid(sendData: .monero(token: token, amount: moneroAmount, address: address))
    }
}
