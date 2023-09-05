import Foundation
import MarketKit
import RxSwift
import RxRelay
import HsToolKit

class SendBitcoinService {
    private let disposeBag = DisposeBag()
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).send-bitcoin-service")

    let token: Token
    let mode: SendBaseService.Mode

    private let amountService: IAmountInputService
    private let amountCautionService: SendAmountCautionService
    private let addressService: AddressService
    private let adapterService: SendBitcoinAdapterService
    private let feeRateService: FeeRateService
    private let timeLockErrorService: SendTimeLockErrorService?

    private let stateRelay = PublishRelay<SendBaseService.State>()
    private(set) var state: SendBaseService.State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(amountService: IAmountInputService, amountCautionService: SendAmountCautionService, addressService: AddressService, adapterService: SendBitcoinAdapterService, feeRateService: FeeRateService, timeLockErrorService: SendTimeLockErrorService?, reachabilityManager: IReachabilityManager, token: Token, mode: SendBaseService.Mode) {
        self.amountService = amountService
        self.amountCautionService = amountCautionService
        self.addressService = addressService
        self.adapterService = adapterService
        self.feeRateService = feeRateService
        self.timeLockErrorService = timeLockErrorService
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
        subscribe(scheduler, disposeBag, feeRateService.statusObservable) { [weak self] _ in self?.syncState() }

        if let timeLockErrorService = timeLockErrorService {
            subscribe(scheduler, disposeBag, timeLockErrorService.errorObservable) { [weak self] _ in
                self?.syncState()
            }
        }
    }

    private func syncState() {
        guard amountCautionService.amountCaution == nil,
           !amountService.amount.isZero else {

            state = .notReady
            return
        }

        if addressService.state.isLoading || feeRateService.status.isLoading {
            state = .loading
            return
        }

        guard addressService.state.address != nil else {
            state = .notReady
            return
        }

        if timeLockErrorService?.error != nil {
            state = .notReady
            return
        }

        if feeRateService.status.data == nil {
            state = .notReady
            return
        }

        state = .ready
    }

}

extension SendBitcoinService: ISendBaseService {

    var stateObservable: Observable<SendBaseService.State> {
        stateRelay.asObservable()
    }

}
