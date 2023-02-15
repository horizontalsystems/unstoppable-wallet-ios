import BigInt
import EvmKit
import MarketKit
import RxRelay
import RxSwift

class EvmSendSettingsService {
    let feeService: IEvmFeeService
    let nonceService: NonceService

    private var disposeBag = DisposeBag()
    private var gasPriceDisposeBag = DisposeBag()

    private let statusRelay = PublishRelay<DataStatus<FallibleData<Transaction>>>()
    private(set) var status: DataStatus<FallibleData<Transaction>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(feeService: IEvmFeeService, nonceService: NonceService) {
        self.feeService = feeService
        self.nonceService = nonceService

        subscribe(disposeBag, feeService.statusObservable) { [weak self] _ in self?.sync() }
        subscribe(disposeBag, nonceService.statusObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        switch (feeService.status, nonceService.status) {
        case (.loading, _), (_, .loading):
            status = .loading
        case (.failed(let error), _), (_, .failed(let error)):
            status = .failed(error)
        default:
            guard case .completed(let fallibleTransaction) = feeService.status else {
                return
            }

            guard case .completed(let fallibleNonce) = nonceService.status else {
                return
            }

            status = .completed(FallibleData<Transaction>(
                    data: Transaction(
                            transactionData: fallibleTransaction.data.transactionData,
                            gasData: fallibleTransaction.data.gasData,
                            nonce: fallibleNonce.data
                    ),
                    errors: fallibleTransaction.errors + fallibleNonce.errors, warnings: fallibleTransaction.warnings)
            )
        }
    }

}

extension EvmSendSettingsService {

    var statusObservable: Observable<DataStatus<FallibleData<Transaction>>> {
        statusRelay.asObservable()
    }

}

extension EvmSendSettingsService {

    struct Transaction {
        let transactionData: TransactionData
        let gasData: EvmFeeModule.GasData
        let nonce: Int
    }

}
