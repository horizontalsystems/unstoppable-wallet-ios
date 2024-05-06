import Combine
import Foundation
import MarketKit
import RxSwift

class BinancePreSendHandler {
    private let token: Token
    private let adapter: ISendBinanceAdapter & IBalanceAdapter

    private let balanceStateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceDataSubject = PassthroughSubject<BalanceData, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ISendBinanceAdapter & IBalanceAdapter) {
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
            .subscribe { [weak self] _ in
                self?.onUpdateBalance()
            }
            .disposed(by: disposeBag)
    }

    private func onUpdateBalance() {
        balanceDataSubject.send(BalanceData(available: adapter.availableBalance))
    }
}

extension BinancePreSendHandler: IPreSendHandler {
    var hasMemo: Bool {
        true
    }

    var balanceState: AdapterState {
        adapter.balanceState
    }

    var balanceStatePublisher: AnyPublisher<AdapterState, Never> {
        balanceStateSubject.eraseToAnyPublisher()
    }

    var balanceData: BalanceData {
        BalanceData(available: adapter.availableBalance)
    }

    var balanceDataPublisher: AnyPublisher<BalanceData, Never> {
        balanceDataSubject.eraseToAnyPublisher()
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendData? {
        let memo = memo?.trimmingCharacters(in: .whitespaces)
        return .binance(token: token, amount: amount, address: address, memo: memo.flatMap { $0.isEmpty ? nil : $0 })
    }
}
