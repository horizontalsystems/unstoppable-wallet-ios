import Combine
import Foundation
import MarketKit
import NearKit
import RxSwift

/// The receiver checks of Android `NearAddressValidator`, which on iOS live here because the address
/// parser does not know the account: a well-formed account id, never the account itself, and a named
/// account that exists. An implicit (64-hex) receiver is not asked about: the first transfer creates
/// it. The existence lookup is permissive: only a definite "no" blocks the form, an unanswered one
/// lets the address through (the kit asks again before a NEAR transfer).
class NearPreSendHandler: PreSendHandler {
    override class func instance(wallet: Wallet, address: ResolvedAddress?) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ISendNearAdapter & IBalanceAdapter else { return nil }
        return NearPreSendHandler(token: wallet.token, adapter: adapter, address: address?.address)
    }

    private let token: Token
    private let adapter: ISendNearAdapter & IBalanceAdapter

    /// The answer for the address it was asked about; nil while unknown or when the node failed to answer.
    private var accountExists: (address: String, exists: Bool?)?
    private(set) var lookupTask: Task<Void, Never>?
    /// Bumped on every address change, so a lookup started for an earlier address never lands.
    private var lookupGeneration = 0

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()
    // NEAR has no destination tag: the field stays hidden, and a republished .hidden is the signal
    // the form recomputes on once the lookup answers (as XrpPreSendHandler)
    private let destinationTagStateSubject = PassthroughSubject<DestinationTagState, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ISendNearAdapter & IBalanceAdapter, address: String?) {
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

        lookup(address: address)
    }

    deinit {
        lookupTask?.cancel()
    }

    private func lookup(address: String?) {
        lookupTask?.cancel()
        lookupGeneration += 1
        accountExists = nil

        guard let address, Self.needsExistenceCheck(address: address) else { return }

        let generation = lookupGeneration

        lookupTask = Task { [weak self, adapter] in
            let exists = try? await adapter.doesAccountExist(address: address)
            if Task.isCancelled { return }
            guard let self else { return }

            // checked and applied on main, where set(address:) runs, so a stale answer cannot
            // slip in between the check and the write
            await MainActor.run {
                guard generation == self.lookupGeneration else { return }
                self.accountExists = (address: address, exists: exists)
                self.destinationTagStateSubject.send(.hidden)
            }
        }
    }

    // a named account exists only once created; an implicit one is created by the first transfer
    static func needsExistenceCheck(address: String) -> Bool {
        NearKit.Kit.isValid(accountId: address) && !NearKit.Kit.isImplicit(accountId: address)
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

    var destinationTagStatePublisher: AnyPublisher<DestinationTagState, Never> {
        destinationTagStateSubject.eraseToAnyPublisher()
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

        // a definite "no" is a property of the address, so it belongs here; an unknown answer is not
        if let accountExists, accountExists.address == address, accountExists.exists == false {
            return invalid("send.address.invalid_address".localized)
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

    func set(address: String?) {
        lookup(address: address)
    }
}
