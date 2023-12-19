import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class SendFeeService {
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).send-fee-service")

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
        if let feeValueService {
            subscribe(feeRateDisposeBag, feeValueService.feeStateObservable) { [weak self] in
                self?.sync(feeState: $0)
            }
        }
    }

    private func sync(feeState: DataStatus<Decimal>) {
        switch feeState {
        case .loading: state = .loading
        case let .failed(error): state = .failed(error)
        case let .completed(value):
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
        case let .amount(value):
            state = .completed(State(primaryInfo: amountInfo(value: value), secondaryInfo: secondaryInfo))
        case let .amountInfo(value):
            let amountInfo = value ?? amountInfo(value: fiatService.coinAmount)
            state = .completed(State(primaryInfo: amountInfo, secondaryInfo: secondaryInfo))
        }
    }
}

extension SendFeeService {
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
