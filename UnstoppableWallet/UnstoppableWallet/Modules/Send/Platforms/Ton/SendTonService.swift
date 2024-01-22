import Foundation
import HsExtensions
import HsToolKit
import MarketKit
import RxRelay
import RxSwift

class SendTonService {
    private let disposeBag = DisposeBag()
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).send-bitcoin-service")

    let token: Token
    let mode: SendBaseService.Mode

    private let amountService: IAmountInputService
    private let amountCautionService: SendAmountCautionService
    private let addressService: AddressService
    private let memoService: SendMemoInputService
    private let adapter: ISendTonAdapter
    private var tasks = Set<AnyTask>()

    private let stateRelay = PublishRelay<SendBaseService.State>()
    private(set) var state: SendBaseService.State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let feeStateRelay = BehaviorRelay<DataStatus<Decimal>>(value: .loading)
    private(set) var feeState: DataStatus<Decimal> = .loading {
        didSet {
            if !feeState.equalTo(oldValue) {
                feeStateRelay.accept(feeState)
            }
        }
    }

    private let availableBalanceRelay: BehaviorRelay<DataStatus<Decimal>>
    private(set) var availableBalance: DataStatus<Decimal> {
        didSet {
            if !availableBalance.equalTo(oldValue) {
                availableBalanceRelay.accept(availableBalance)
            }
        }
    }

    init(amountService: IAmountInputService, amountCautionService: SendAmountCautionService, addressService: AddressService, memoService: SendMemoInputService, adapter: ISendTonAdapter, reachabilityManager: IReachabilityManager, token: Token, mode: SendBaseService.Mode) {
        self.amountService = amountService
        self.amountCautionService = amountCautionService
        self.addressService = addressService
        self.memoService = memoService
        self.adapter = adapter
        self.token = token
        self.mode = mode

        switch mode {
        case let .prefilled(address, amount):
            addressService.set(text: address)
            if let amount { addressService.publishAmountRelay.accept(amount) }
        case let .predefined(address): addressService.set(text: address)
        case .send: ()
        }

        availableBalance = .completed(adapter.availableBalance)
        availableBalanceRelay = .init(value: .completed(adapter.availableBalance))

        subscribe(MainScheduler.instance, disposeBag, reachabilityManager.reachabilityObservable) { [weak self] isReachable in
            if isReachable {
                self?.syncState()
            }
        }

        subscribe(scheduler, disposeBag, amountService.amountObservable) { [weak self] _ in self?.syncState() }
        subscribe(scheduler, disposeBag, amountCautionService.amountCautionObservable) { [weak self] _ in self?.syncState() }
        subscribe(scheduler, disposeBag, addressService.stateObservable) { [weak self] _ in self?.syncState() }

        loadFee()
    }

    private func syncState() {
        guard amountCautionService.amountCaution == nil, !amountService.amount.isZero else {
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

        guard feeState.data != nil else {
            state = .notReady
            return
        }

        state = .ready
    }

    private func loadFee() {
        Task { [weak self, adapter] in
            do {
                let fee = try await adapter.estimateFee()
                self?.feeState = .completed(fee)
                self?.availableBalance = .completed(max(0, adapter.availableBalance - fee))
            } catch {
                self?.feeState = .failed(error)
                self?.availableBalance = .completed(adapter.availableBalance)
            }
        }
        .store(in: &tasks)
    }
}

extension SendTonService: ISendBaseService {
    var stateObservable: Observable<SendBaseService.State> {
        stateRelay.asObservable()
    }
}

extension SendTonService: ISendService {
    func sendSingle(logger _: HsToolKit.Logger) -> Single<Void> {
        let address: Address
        switch addressService.state {
        case let .success(sendAddress): address = sendAddress
        case let .fetchError(error): return Single.error(error)
        default: return Single.error(AppError.addressInvalid)
        }

        let amount = amountService.amount

        guard !amount.isZero else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        let memo = memoService.memo
        return Single.create { [adapter] observer in
            let task = Task { [adapter] in
                do {
                    try await adapter.send(recipient: address.raw, amount: amount, memo: memo)
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

extension SendTonService: ISendXFeeValueService {
    var feeStateObservable: Observable<DataStatus<Decimal>> {
        feeStateRelay.asObservable()
    }
}

extension SendTonService: IAvailableBalanceService {
    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        availableBalanceRelay.asObservable()
    }
}

extension SendTonService: IMemoAvailableService {
    var isAvailable: Bool {
        true
    }

    var isAvailableObservable: Observable<Bool> {
        Observable.empty()
    }
}
