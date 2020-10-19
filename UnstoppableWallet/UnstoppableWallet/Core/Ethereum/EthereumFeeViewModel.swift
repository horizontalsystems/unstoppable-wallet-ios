import RxSwift
import RxRelay
import RxCocoa

class EthereumFeeViewModel {
    private let service: EthereumTransactionService
    private let coinService: EthereumCoinService

    private let disposeBag = DisposeBag()

    private let feeStatusRelay = BehaviorRelay<DataStatus<AmountData?>>(value: .loading)

    init(service: EthereumTransactionService, coinService: EthereumCoinService) {
        self.service = service
        self.coinService = coinService

        sync(transactionStatus: service.transactionStatus)

        service.transactionStatusObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] transactionStatus in
                    self?.sync(transactionStatus: transactionStatus)
                })
                .disposed(by: disposeBag)
    }

    private func sync(transactionStatus: DataStatus<EthereumTransactionService.Transaction>) {
        feeStatusRelay.accept(transactionStatus.map { transaction in
            coinService.amountData(value: transaction.gasData.fee)
        })
    }

}

extension EthereumFeeViewModel {

    var feeStatusDriver: Driver<DataStatus<AmountData?>> {
        feeStatusRelay.asDriver()
    }

    func set(gasPriceType: EthereumTransactionService.GasPriceType) {
        service.set(gasPriceType: gasPriceType)
    }

}
