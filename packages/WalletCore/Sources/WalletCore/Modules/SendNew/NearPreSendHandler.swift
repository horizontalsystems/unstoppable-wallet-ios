import Combine
import Foundation
import MarketKit
import NearKit
import RxSwift

/// The receiver check of Android `NearAddressValidator` the address parser cannot make, because it
/// does not know the account: never the account itself. Whether a named account exists is checked by
/// the parser (`NearAddressParserItem`), for every screen that takes a NEAR address.
class NearPreSendHandler: PreSendHandler {
    override class func instance(wallet: Wallet, address _: ResolvedAddress?) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ISendNearAdapter & IBalanceAdapter else { return nil }
        return NearPreSendHandler(token: wallet.token, adapter: adapter)
    }

    private let token: Token
    private let adapter: ISendNearAdapter & IBalanceAdapter

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ISendNearAdapter & IBalanceAdapter) {
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
            .subscribe { [weak self] _ in
                guard let self else { return }
                balanceSubject.send(adapter.balanceData.available)
            }
            .disposed(by: disposeBag)
    }

    private func invalid(_ text: String, title: String? = nil) -> SendDataResult {
        .invalid(cautions: [CautionNew(title: title, text: text, type: .error)])
    }

    private func recipientError(address: String) -> SendDataResult? {
        guard NearKit.Kit.isValid(accountId: address) else {
            return invalid("send.address.invalid_address".localized)
        }

        guard address != adapter.address else {
            return invalid("send.address_error.own_address".localized(token.coin.code), title: "send.address.invalid_address".localized)
        }

        return nil
    }
}

extension NearPreSendHandler: IPreSendHandler {
    var state: AdapterState {
        adapter.balanceState
    }

    var statePublisher: AnyPublisher<AdapterState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // the whole spendable balance, as most chains: for NEAR the confirmation takes out what the
    // transfer to the actual receiver needs (NearSendHandler); a token's fee is paid in NEAR
    var balance: Decimal {
        adapter.balanceData.available
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    // only a NEP-141 ft_transfer carries a memo (Android `sendMemoSupport`)
    func memoType(address _: String?) -> MemoType {
        if case .nep141 = token.type {
            return .onChainPublic
        }
        return .none
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        if let error = recipientError(address: address) {
            return error
        }

        let hasMemo = memo.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        let sentMemo = memoType(address: address) == .onChainPublic && hasMemo ? memo : nil

        return .valid(sendData: .near(token: token, amount: amount, address: address, memo: sentMemo))
    }

    // To the provider's deposit address, never with a memo: a NEAR deposit is a plain transfer,
    // which has no field for one (Android `memoDelivery = None`).
    func depositSendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        if let error = recipientError(address: address) {
            return error
        }

        guard memo?.isEmpty != false else {
            return .invalid(cautions: [])
        }

        return .valid(sendData: .near(token: token, amount: amount, address: address, memo: nil))
    }

    // Decided by the chain, not by memoType(address:): the default would let a token deposit carry
    // a text memo, which the provider never reads.
    func depositSendData(amount: Decimal, address: String, attachment: USwapMultiSwapApi.Attachment?, settings _: PreSendSettingsSnapshot?) throws -> SendDataResult {
        _ = try USwapMultiSwapApi.Attachment.memo(attachment, memoType: token.blockchainType.memoType)
        return depositSendData(amount: amount, address: address, memo: nil)
    }
}
