import BigInt
import RxRelay
import RxSwift
import MarketKit

class SendSettingsService {
    private let feeService: SendFeeService
    private let feeRateService: FeeRateService
    private let amountCautionService: SendAmountCautionService
    private let token: Token

    private var disposeBag = DisposeBag()
    private var gasPriceDisposeBag = DisposeBag()

    private let statusRelay = PublishRelay<DataStatus<Void>>()
    private(set) var status: DataStatus<Void> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(feeService: SendFeeService, feeRateService: FeeRateService, amountCautionService: SendAmountCautionService, token: Token) {
        self.feeService = feeService
        self.feeRateService = feeRateService
        self.amountCautionService = amountCautionService
        self.token = token

        subscribe(disposeBag, feeService.stateObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        switch feeService.state {
        case .loading:
            status = .loading
        case .failed(let error):
            status = .failed(error)
        default:
            status = .completed(())
        }
    }

}

extension SendSettingsService {

    var statusObservable: Observable<DataStatus<Void>> {
        statusRelay.asObservable()
    }

}
