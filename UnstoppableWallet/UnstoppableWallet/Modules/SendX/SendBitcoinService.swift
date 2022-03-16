import Foundation
import MarketKit
import RxSwift
import RxRelay
import HsToolKit

class SendBitcoinService {
    private let disposeBag = DisposeBag()

    let sendPlatformCoin: PlatformCoin
    private let amountService: IAmountInputService
    private let amountCautionService: AmountCautionService
    private let addressService: AddressService
    private let adapterService: SendBitcoinAdapterService
    private let feeService: SendXFeeRateService

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(amountService: IAmountInputService, amountCautionService: AmountCautionService, addressService: AddressService, adapterService: SendBitcoinAdapterService, feeService: SendXFeeRateService, reachabilityManager: IReachabilityManager, platformCoin: PlatformCoin) {
        self.amountService = amountService
        self.amountCautionService = amountCautionService
        self.addressService = addressService
        self.adapterService = adapterService
        self.feeService = feeService
        sendPlatformCoin = platformCoin

        subscribe(MainScheduler.instance, disposeBag, reachabilityManager.reachabilityObservable) { [weak self] isReachable in
            if isReachable {
                self?.syncState()
            }
        }

        subscribe(disposeBag, amountService.amountObservable) { [weak self] _ in self?.syncState() }
        subscribe(disposeBag, amountCautionService.amountCautionObservable) { [weak self] _ in self?.syncState() }
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in self?.syncState() }
        subscribe(disposeBag, feeService.feeRateObservable) { [weak self] _ in self?.syncState() }
    }

    private func syncState() {
        let amount = amountService.amount
        guard amountCautionService.amountCaution == nil,
           !amount.isZero else {
            state = .notReady
            return
        }

        if addressService.state.isLoading || feeService.feeRate.isLoading {
            state = .loading
            return
        }

        if addressService.state.address != nil,
           feeService.feeRate.data != nil {
            state = .ready
        } else {
            state = .notReady
        }
    }

}

extension SendBitcoinService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension SendBitcoinService {

    enum State {
        case loading
        case ready //SendXData
        case notReady
    }

    enum AmountError: Error {
        case invalidDecimal
        case insufficientBalance
    }

    enum AmountWarning {
        case coinNeededForFee
    }

}
