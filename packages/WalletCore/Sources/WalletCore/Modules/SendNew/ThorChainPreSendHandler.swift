import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainPreSendHandler: PreSendHandler, IPreSendHandler {
    let token: Token
    private let adapter: ThorChainAdapter
    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()
    private let disposeBag = DisposeBag()

    override class func instance(wallet: Wallet, address _: ResolvedAddress) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ThorChainAdapter else { return nil }
        return ThorChainPreSendHandler(token: wallet.token, adapter: adapter)
    }

    init(token: Token, adapter: ThorChainAdapter) {
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

    var state: AdapterState { adapter.balanceState }
    var statePublisher: AnyPublisher<AdapterState, Never> { stateSubject.eraseToAnyPublisher() }
    // The fee is charged in RUNE, so only a RUNE send has to leave room for it. This is
    // the balance the amount is chosen against, and nothing re-reads it before signing.
    var balance: Decimal {
        let available = adapter.balanceData.available
        return adapter.isNativeCoin ? max(0, available - adapter.fee) : available
    }
    var balancePublisher: AnyPublisher<Decimal, Never> { balanceSubject.eraseToAnyPublisher() }
    func hasMemo(address _: String?) -> Bool { true }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        do {
            let amountBaseUnits = try ThorChainSendHelper.baseUnits(amount)
            let recipient = try ThorChainKit.Address(address, network: .mainnet)
            // A token draws its amount from its own balance and its fee from RUNE, so a
            // RUNE balance too small for the fee has to be refused here: nothing reads a
            // balance again before signing.
            guard adapter.isNativeCoin || adapter.runeAvailableBalance >= adapter.fee else {
                throw ThorChainKit.SendError.insufficientBalance
            }
            return .valid(sendData: .thorChain(token: token, amount: .exact(amountBaseUnits), recipient: recipient, memo: memo))
        } catch {
            return .invalid(cautions: [ThorChainSendHelper.caution(error, feeToken: token)])
        }
    }
}
