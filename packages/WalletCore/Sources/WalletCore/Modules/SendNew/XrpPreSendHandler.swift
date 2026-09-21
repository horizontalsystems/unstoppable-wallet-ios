import Combine
import Foundation
import MarketKit
import RxSwift
import XrpKit

/// Asks the ledger what the destination demands, to shape the form: whether the RequireDestTag flag
/// makes the tag mandatory, and whether an issued token has a trust line to land on. Both are
/// permissive when the node does not answer, as Android (`XrpChainPlugin.sendExtraInput` leaves the
/// tag optional, `XrpAddressValidator` keeps a well-formed address valid): a blip while typing must
/// not lock the form. The two gates that must not pass on an unknown answer, a minimum first deposit
/// into an unfunded account and a required destination tag, live on the confirmation in
/// `XrpSendHelper.destinationError`, which is re-asked on every refresh. The trust line stays here
/// and stays permissive, as Android: an issued payment the recipient cannot accept costs the fee the
/// ledger burns, not the amount. Memo size is enforced by the kit.
class XrpPreSendHandler: PreSendHandler {
    override class func instance(wallet: Wallet, address: ResolvedAddress) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ISendXrpAdapter & IBalanceAdapter else { return nil }
        return XrpPreSendHandler(token: wallet.token, adapter: adapter, address: address.address)
    }

    private let token: Token
    private let adapter: ISendXrpAdapter & IBalanceAdapter
    private let network: XrpKit.Network

    private let destination: (classic: String, tag: UInt32?)?
    private let addressError: Error?

    /// nil while unknown: the node has not answered yet, or it failed to.
    private var requiresTag: Bool?
    private var canReceive: Bool?
    private var lookupTask: Task<Void, Never>?

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()
    private let destinationTagStateSubject = CurrentValueSubject<DestinationTagState, Never>(.optional)

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ISendXrpAdapter & IBalanceAdapter, address: String) {
        self.token = token
        self.adapter = adapter
        network = XrpKitManager.network

        do {
            destination = try XrpKit.Kit.resolveDestination(address: address, tag: nil, network: network)
            addressError = nil
        } catch {
            destination = nil
            addressError = error
        }

        super.init()

        if let tag = destination?.tag {
            destinationTagStateSubject.send(.fixed(tag))
        }

        adapter.balanceStateUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] state in
                self?.stateSubject.send(state)
            }
            .disposed(by: disposeBag)

        adapter.balanceDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] balanceData in
                guard let self else { return }
                balanceSubject.send(spendable(available: balanceData.available))
            }
            .disposed(by: disposeBag)

        lookupDestination()
    }

    deinit {
        lookupTask?.cancel()
    }

    private func lookupDestination() {
        guard let destination else { return }

        lookupTask = Task { [weak self, adapter] in
            // asked separately, as the two Android call sites are: one node hiccup must not throw
            // away the other answer
            let requiresTag = try? await adapter.requiresDestinationTag(address: destination.classic)
            if Task.isCancelled { return }
            let canReceive = try? await adapter.canReceive(address: destination.classic)
            if Task.isCancelled { return }

            self?.handle(requiresTag: requiresTag, canReceive: canReceive)
        }
    }

    private func handle(requiresTag: Bool?, canReceive: Bool?) {
        self.requiresTag = requiresTag
        self.canReceive = canReceive

        // Always publish, even when the value does not change: this is the signal the form waits on
        // to recompute. Returning early for a pinned tag left the send button dead whenever the
        // amount had been typed before the node answered.
        if case let .fixed(tag) = destinationTagStateSubject.value {
            // a tag packed in the X-address stays pinned whatever the account says
            destinationTagStateSubject.send(.fixed(tag))
        } else {
            destinationTagStateSubject.send(requiresTag == true ? .required : .optional)
        }
    }

    /// What the form may actually offer: the fee is paid in XRP on top of the amount, so a native
    /// send of the whole spendable balance would always fail the fee check (Android
    /// `XrpAdapter.maxSendableBalance`). An issued token is not reduced: its fee is a separate asset.
    private func spendable(available: Decimal) -> Decimal {
        guard token.type.isNative else {
            return available
        }

        return max(0, available - adapter.fee)
    }

    private func invalid(_ text: String, title: String? = nil) -> SendDataResult {
        .invalid(cautions: [CautionNew(title: title, text: text, type: .error)])
    }
}

extension XrpPreSendHandler: IPreSendHandler {
    var state: AdapterState {
        adapter.balanceState
    }

    var statePublisher: AnyPublisher<AdapterState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balance: Decimal {
        spendable(available: adapter.balanceData.available)
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    // No memo on the XRP form, as Android: the tag is the recipient-facing field.
    func memoType(address _: String?) -> MemoType {
        .none
    }

    var destinationTagState: DestinationTagState {
        destinationTagStateSubject.value
    }

    var destinationTagStatePublisher: AnyPublisher<DestinationTagState, Never> {
        destinationTagStateSubject.eraseToAnyPublisher()
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        sendData(amount: amount, address: address, memo: memo, destinationTagInput: "")
    }

    func sendData(amount: Decimal, address _: String, memo _: String?, destinationTagInput: String) -> SendDataResult {
        guard let destination else {
            return invalid((addressError ?? XrpKit.AddressError.invalidFormat).smartDescription)
        }

        // as Tron: the ledger refuses a payment to the sending account (temREDUNDANT), so refuse it
        // here; compared on the classic address so an own X-address is caught too
        guard destination.classic != adapter.address else {
            return invalid("send.address_error.own_address".localized(token.coin.code), title: "send.address.invalid_address".localized)
        }

        let tag: UInt32?
        if let fixed = destination.tag {
            tag = fixed
        } else {
            let input = destinationTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.isEmpty {
                tag = nil
            } else if let parsed = XrpDestinationTag.parse(input) {
                tag = parsed
            } else {
                return invalid("send.xrp.destination_tag.invalid".localized, title: "send.xrp.destination_tag".localized)
            }
        }

        // a definite "no" is a property of the address, so it belongs here; an unknown answer is not
        if requiresTag == true, tag == nil {
            return invalid("send.xrp.destination_tag.required".localized, title: "send.xrp.destination_tag".localized)
        }

        if !token.type.isNative, canReceive == false {
            return invalid("send.stellar.no_trustline.description".localized, title: "send.stellar.no_trustline.title".localized)
        }

        return .valid(sendData: .xrp(token: token, data: .payment(amount: amount, address: destination.classic), destinationTag: tag))
    }
}
