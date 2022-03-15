import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class SendFeeService {
    private let disposeBag = DisposeBag()
    private var feeRateDisposeBag = DisposeBag()

    weak var feeValueService: ISendXFeeValueService? {
        didSet {
            setFeeValueService()
        }
    }

    private let fiatService: FiatService
    private let feeCoin: PlatformCoin

    private let stateRelay = BehaviorRelay<DataStatus<State>>(value: .loading)
    private(set) var state: DataStatus<State> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(fiatService: FiatService, feeCoin: PlatformCoin) {
        self.fiatService = fiatService
        self.feeCoin = feeCoin

        fiatService.set(platformCoin: feeCoin)
        subscribe(disposeBag, fiatService.amountAlreadyUpdatedObservable) { [weak self] in self?.sync() }
        subscribe(disposeBag, fiatService.primaryInfoObservable) { [weak self] in self?.sync(primaryInfo: $0) }
        subscribe(disposeBag, fiatService.secondaryAmountInfoObservable) { [weak self] in self?.sync(secondaryInfo: $0) }
    }

    private func setFeeValueService() {
        feeRateDisposeBag = DisposeBag()
        if let feeValueService = feeValueService {
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
        let coinValue = CoinValue(kind: .platformCoin(platformCoin: feeCoin), value: value)
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