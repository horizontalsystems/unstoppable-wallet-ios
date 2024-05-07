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
            .subscribe { [weak self] state in
                self?.stateSubject.send(state)
            }
            .disposed(by: disposeBag)

        adapter.balanceDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self, adapter] balanceData in
                let balance = max(0, balanceData.available - adapter.fee)
                self?.balanceSubject.send(balance)
            }
            .disposed(by: disposeBag)
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
        max(0, adapter.balanceData.available - adapter.fee)
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    func validate(address: String) -> Caution? {
        do {
            _ = try adapter.validate(address: address, checkSendToSelf: true)
            return nil
        } catch {
            return Caution(text: error.smartDescription, type: .error)
        }
    }

    func hasMemo(address: String?) -> Bool {
        guard let address, let addressType = try? adapter.validate(address: address, checkSendToSelf: true) else {
            return false
        }

        return addressType == .shielded
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        guard let recipient = adapter.recipient(from: address) else {
            return .invalid(cautions: [])
        }

        let sendData: SendData = .zcash(amount: amount, recipient: recipient, memo: memo)

        return .valid(sendData: sendData)
    }
}
