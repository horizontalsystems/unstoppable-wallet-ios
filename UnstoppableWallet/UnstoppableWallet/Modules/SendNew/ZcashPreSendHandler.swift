import Combine
import Foundation
import MarketKit
import RxSwift

class ZcashPreSendHandler {
    private let token: Token
    private let adapter: ISendZcashAdapter & IBalanceAdapter

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ISendZcashAdapter & IBalanceAdapter) {
        self.token = token
        self.adapter = adapter

        adapter.balanceStateUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] in
                self?.sync(state: $0)
            }
            .disposed(by: disposeBag)

        adapter.balanceDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] in
                self?.updateBalanceSubject(balanceData: $0)
            }
            .disposed(by: disposeBag)
    }
    
    private func sync(state: AdapterState) {
        if adapter.areFundsSpendable {
            stateSubject.send(.synced)
            return
        }

        stateSubject.send(state)
    }
    
    private func updateBalanceSubject(balanceData: BalanceData) {
        // return all available balance
        let balance = max(0, balanceData.available)
        balanceSubject.send(balance)
    }
}

extension ZcashPreSendHandler: IPreSendHandler {
    var state: AdapterState {
        adapter.balanceState
    }

    var statePublisher: AnyPublisher<AdapterState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balance: Decimal {
        max(0, adapter.balanceData.available)
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    func hasMemo(address: String?) -> Bool {
        guard let address, let addressType = try? adapter.validate(address: address, checkSendToSelf: true) else {
            return false
        }

        return addressType == .shielded
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        do {
            _ = try adapter.validate(address: address, checkSendToSelf: true)
        } catch {
            return .invalid(cautions: [CautionNew(text: error.smartDescription, type: .error)])
        }

        guard let recipient = adapter.recipient(from: address) else {
            return .invalid(cautions: [])
        }

        let sendData: SendData = .zcash(amount: amount, recipient: recipient, memo: memo)

        return .valid(sendData: sendData)
    }
}
