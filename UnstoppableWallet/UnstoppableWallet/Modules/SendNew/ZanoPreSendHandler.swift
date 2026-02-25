import Combine
import Foundation
import MarketKit
import RxSwift
import SwiftUI
import ZanoKit

class ZanoPreSendHandler {
    private let token: Token
    private let adapter: ZanoAdapter

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ZanoAdapter) {
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

extension ZanoPreSendHandler: IPreSendHandler {
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

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        if !ZanoAdapter.isValidAddress(address) {
            return .invalid(cautions: [CautionNew(text: "send.address.invalid_address".localized, type: .error)])
        }

        let zanoAmount: ZanoSendAmount
        if amount == adapter.balanceData.available {
            zanoAmount = .all(amount)
        } else {
            zanoAmount = .value(amount)
        }

        return .valid(sendData: .zano(token: token, amount: zanoAmount, address: address, memo: memo))
    }
}
