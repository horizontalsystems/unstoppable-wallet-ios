import Foundation
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

    private let stateRelay = PublishRelay<SendBaseService.State>()
    private(set) var state: SendBaseService.State = .notReady {
        didSet {
            stateRelay.accept(state)
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
        guard amountCautionService.amountCaution == nil,
              !amountService.amount.isZero
        else {
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

        let memo = memoService.memo // todo

        return Single.create { [adapter] observer in
            let task = Task { [adapter] in
                do {
                    try await adapter.send(recipient: address.raw, amount: amount)
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
    var feeState: DataStatus<Decimal> {
//        .completed(adapter.fee)
        .completed(0.005)
    }

    var feeStateObservable: Observable<DataStatus<Decimal>> {
        .just(feeState)
    }
}

extension SendTonService: IAvailableBalanceService {
    var availableBalance: DataStatus<Decimal> {
        .completed(adapter.availableBalance)
    }

    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        .just(availableBalance)
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
