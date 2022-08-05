import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

protocol ISendFeeService {
    var editableObservable: Observable<Bool> { get }
    var defaultFeeObservable: Observable<Bool> { get }
    var stateObservable: Observable<DataStatus<SendFeeService.State>> { get }
}

class SendFeeService: ISendFeeService {
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.send-fee-service")

    private let disposeBag = DisposeBag()
    private var feeRateDisposeBag = DisposeBag()

    weak var feeValueService: ISendXFeeValueService? {
        didSet {
            setFeeValueService()
        }
    }

    private let fiatService: FiatService
    private let feeToken: Token

    private let stateRelay = BehaviorRelay<DataStatus<State>>(value: .loading)
    private(set) var state: DataStatus<State> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let editableRelay = BehaviorRelay<Bool>(value: false)
    private(set) var editable: Bool = false {
        didSet {
            editableRelay.accept(editable)
        }
    }

    init(fiatService: FiatService, feeToken: Token) {
        self.fiatService = fiatService
        self.feeToken = feeToken

        fiatService.set(token: feeToken)
        subscribe(scheduler, disposeBag, fiatService.amountAlreadyUpdatedObservable) { [weak self] in self?.sync() }
        subscribe(scheduler, disposeBag, fiatService.coinAmountObservable) { [weak self] _ in self?.sync() }
        subscribe(scheduler, disposeBag, fiatService.primaryInfoObservable) { [weak self] in self?.sync(primaryInfo: $0) }
        subscribe(scheduler, disposeBag, fiatService.secondaryAmountInfoObservable) { [weak self] in self?.sync(secondaryInfo: $0) }
    }

    private func setFeeValueService() {
        feeRateDisposeBag = DisposeBag()
        if let feeValueService = feeValueService {
            editable = feeValueService.editable
            subscribe(feeRateDisposeBag, feeValueService.feeStateObservable) { [weak self] in
                self?.sync(feeState: $0)
            }
        }
    }

    private func sync(feeState: DataStatus<Decimal>) {
        switch feeState {
        case .loading: state = .loading
        case .failed(let error): state = .failed(error)
        case .completed(let value):
            fiatService.set(coinAmount: value)
        }
    }

    private func amountInfo(value: Decimal) -> AmountInfo {
        let coinValue = CoinValue(kind: .token(token: feeToken), value: value)
        return AmountInfo.coinValue(coinValue: coinValue)
    }

    private func sync(primaryInfo: FiatService.PrimaryInfo? = nil, secondaryInfo: AmountInfo? = nil) {
        let primaryInfo = primaryInfo ?? fiatService.primaryInfo
        let secondaryInfo = secondaryInfo ?? fiatService.secondaryAmountInfo

        switch primaryInfo {
        case .amount(let value):
            state = .completed(State(primaryInfo: amountInfo(value: value), secondaryInfo: secondaryInfo))
        case .amountInfo(let value):
            let amountInfo = value ?? amountInfo(value: fiatService.coinAmount)
            state = .completed(State(primaryInfo: amountInfo, secondaryInfo: secondaryInfo))
        }
    }

    var editableObservable: Observable<Bool> {
        editableRelay.asObservable()
    }

    var defaultFeeObservable: Observable<Bool> {
        .just(true)
    }

    var stateObservable: Observable<DataStatus<State>> {
        stateRelay.asObservable()
    }

}

extension SendFeeService {

    struct State {
        let primaryInfo: AmountInfo
        let secondaryInfo: AmountInfo?
    }

}