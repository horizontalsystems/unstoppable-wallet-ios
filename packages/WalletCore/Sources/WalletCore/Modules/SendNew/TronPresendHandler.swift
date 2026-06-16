import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import TronKit

open class TronPreSendHandler: PreSendHandler {
    public let token: Token
    private let adapter: ISendTronAdapter & IBalanceAdapter

    open override class func instance(wallet: Wallet, address _: ResolvedAddress) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ISendTronAdapter & IBalanceAdapter else { return nil }
        return TronPreSendHandler(token: wallet.token, adapter: adapter)
    }

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    public init(token: Token, adapter: ISendTronAdapter & IBalanceAdapter) {
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

    open func makeSendData(amountBigUInt: BigUInt, tronAddress: TronKit.Address, memo: String?) -> SendData {
        let contract = adapter.contract(amount: amountBigUInt, address: tronAddress, memo: memo)
        return .tron(token: token, contract: contract)
    }
}

extension TronPreSendHandler: IPreSendHandler {
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

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        guard let amountBigUInt = BigUInt(amount.hs.roundedString(decimal: token.decimals)) else {
            return .invalid(cautions: [])
        }

        guard let tronAddress = try? TronKit.Address(address: address) else {
            return .invalid(cautions: [])
        }

        guard tronAddress != adapter.tronKitWrapper.tronKit.receiveAddress else {
            return .invalid(cautions: [CautionNew(title: "send.address.invalid_address".localized, text: "send.address_error.own_address".localized(token.coin.code), type: .error)])
        }

        return .valid(sendData: makeSendData(amountBigUInt: amountBigUInt, tronAddress: tronAddress, memo: memo))
    }
}
