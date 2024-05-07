import BigInt
import Combine
import EvmKit
import Foundation
import MarketKit
import RxSwift

class EvmPreSendHandler {
    private let token: Token
    private let adapter: ISendEthereumAdapter & IBalanceAdapter

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ISendEthereumAdapter & IBalanceAdapter) {
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

extension EvmPreSendHandler: IPreSendHandler {
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

    func sendData(amount: Decimal, address: String, memo _: String?) -> SendDataResult {
        guard let evmAmount = BigUInt(amount.hs.roundedString(decimal: token.decimals)) else {
            return .invalid(cautions: [])
        }

        guard let evmAddress = try? EvmKit.Address(hex: address) else {
            return .invalid(cautions: [])
        }

        let transactionData = adapter.transactionData(amount: evmAmount, address: evmAddress)

        return .valid(sendData: .evm(blockchainType: token.blockchainType, transactionData: transactionData))
    }
}
