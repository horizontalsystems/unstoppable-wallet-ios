import Foundation
import MarketKit
import RxSwift
import RxRelay
import HsToolKit
import ZcashLightClientKit

class SendZcashService {
    private let disposeBag = DisposeBag()
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).send-bitcoin-service")

    let token: Token
    let mode: SendBaseService.Mode

    private let amountService: IAmountInputService
    private let amountCautionService: SendAmountCautionService
    private let addressService: AddressService
    private let memoService: SendMemoInputService
    private let adapter: ISendZcashAdapter

    private let stateRelay = PublishRelay<SendBaseService.State>()
    private(set) var state: SendBaseService.State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var isMemoAvailableRelay = BehaviorRelay<Bool>(value: false)
    private var isMemoAvailable: Bool = false {
        didSet {
            isMemoAvailableRelay.accept(isMemoAvailable)
        }
    }

    init(amountService: IAmountInputService, amountCautionService: SendAmountCautionService, addressService: AddressService, memoService: SendMemoInputService, adapter: ISendZcashAdapter, reachabilityManager: IReachabilityManager, token: Token, mode: SendBaseService.Mode) {
        self.amountService = amountService
        self.amountCautionService = amountCautionService
        self.addressService = addressService
        self.memoService = memoService
        self.adapter = adapter
        self.token = token
        self.mode = mode

        switch mode {
        case .predefined(let address): addressService.set(text: address)
        case .send: ()
        }

        subscribe(MainScheduler.instance, disposeBag, reachabilityManager.reachabilityObservable) { [weak self] isReachable in
            if isReachable {
                self?.syncState()
            }
        }

        subscribe(scheduler, disposeBag, amountService.amountObservable) { [weak self] _ in self?.syncState() }
        subscribe(scheduler, disposeBag, amountCautionService.amountCautionObservable) { [weak self] _ in self?.syncState() }
        subscribe(scheduler, disposeBag, addressService.stateObservable) { [weak self] _ in self?.syncState() }
    }

    private func syncState() {
        let address = addressService.state.address?.raw
        let addressType = address.map { try? adapter.validate(address: $0, checkSendToSelf: true) }
        isMemoAvailable = addressType.map { $0 == .shielded } ?? false

        guard amountCautionService.amountCaution == nil,
           !amountService.amount.isZero else {

            state = .notReady
            return
        }

        if addressService.state.isLoading {
            state = .loading
            return
        }

        guard addressService.state.address != nil else {
            state = .notReady
            return
        }

        state = .ready
    }

}

extension SendZcashService: ISendBaseService {

    var stateObservable: Observable<SendBaseService.State> {
        stateRelay.asObservable()
    }

}

extension SendZcashService: ISendService {

    func sendSingle(logger: HsToolKit.Logger) -> RxSwift.Single<Void> {
        let address: Address
        switch addressService.state {
        case .success(let sendAddress): address = sendAddress
        case .fetchError(let error): return Single.error(error)
        default: return Single.error(AppError.addressInvalid)
        }

        guard !amountService.amount.isZero else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        guard let recipient = adapter.recipient(from: address.raw) else {
            return Single.error(SendTransactionError.invalidAddress)
        }

        return adapter.sendSingle(
                amount: amountService.amount,
                address: recipient,
                memo: memoService.memo.flatMap({ try? Memo(string: $0) })
        )
    }

}

extension SendZcashService: ISendXFeeValueService {

    var feeState: DataStatus<Decimal> {
        .completed(adapter.fee)
    }

    var feeStateObservable: Observable<DataStatus<Decimal>> {
        .just(feeState)
    }

}

extension SendZcashService: IAvailableBalanceService {

    var availableBalance: DataStatus<Decimal> {
        .completed(adapter.availableBalance)
    }

    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        .just(availableBalance)
    }

}

extension SendZcashService: IMemoAvailableService {

    var isAvailable: Bool {
        isMemoAvailable
    }

    var isAvailableObservable: Observable<Bool> {
        isMemoAvailableRelay.asObservable()
    }

}
