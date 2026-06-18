import Combine
import Foundation
import MarketKit
import RxSwift
import StellarKit

class StellarPreSendHandler: PreSendHandler {
    override class func instance(wallet: Wallet, address _: ResolvedAddress) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? StellarAdapter else { return nil }
        return StellarPreSendHandler(token: wallet.token, adapter: adapter)
    }

    private let token: Token
    private let adapter: StellarAdapter

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: StellarAdapter) {
        self.token = token
        self.adapter = adapter

        super.init()

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

extension StellarPreSendHandler: IPreSendHandler {
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
        do {
            try StellarKit.Kit.validate(accountId: address)
            let data: StellarSendData = .payment(asset: adapter.asset, amount: amount, accountId: address)
            return .valid(sendData: .stellar(data: data, token: token, memo: memo))
        } catch {
            return .invalid(cautions: [CautionNew(text: error.smartDescription, type: .error)])
        }
    }
}
