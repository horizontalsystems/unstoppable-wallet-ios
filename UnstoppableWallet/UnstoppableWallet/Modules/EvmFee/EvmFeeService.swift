import EthereumKit
import MarketKit
import BigInt
import RxSwift
import RxRelay

class EvmFeeService {
    private let evmKit: EthereumKit.Kit
    private let gasPriceService: IGasPriceService
    private let gasDataService: IEvmGasDataService

    private var transactionData: TransactionData

    private let transactionStatusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.Transaction>>>()
    private(set) var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> = .loading {
        didSet {
            transactionStatusRelay.accept(status)
        }
    }

    private var disposeBag = DisposeBag()
    private var gasPriceDisposeBag = DisposeBag()

    init(evmKit: EthereumKit.Kit, gasPriceService: IGasPriceService, gasDataService: IEvmGasDataService, transactionData: TransactionData) {
        self.evmKit = evmKit
        self.gasPriceService = gasPriceService
        self.gasDataService = gasDataService
        self.transactionData = transactionData

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>) {
        switch gasPriceStatus {
        case .loading: status = .loading
        case .failed(let error): status = .failed(error)
        case .completed(let fallibleGasPrice): sync(fallibleGasPrice: fallibleGasPrice)
        }
    }

    private func sync(fallibleGasPrice: FallibleData<GasPrice>) {
        if let transaction = gasDataService.transaction(gasPrice: fallibleGasPrice.data, transactionData: transactionData) {
            sync(transaction: transaction, fallibleGasPrice: fallibleGasPrice)
            return
        }

        disposeBag = DisposeBag()

        transactionSingle(gasPrice: fallibleGasPrice.data, transactionData: transactionData)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] transaction in
                    self?.sync(transaction: transaction, fallibleGasPrice: fallibleGasPrice)
                }, onError: { [weak self] error in
                    self?.status = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func sync(transaction: EvmFeeModule.Transaction, fallibleGasPrice: FallibleData<GasPrice>) {
        var errors: [Error] = fallibleGasPrice.errors

        let totalAmount = transaction.transactionData.value + transaction.gasData.fee
        if totalAmount > evmBalance {
            errors.append(SendEvmTransactionService.TransactionError.insufficientBalance(requiredBalance: totalAmount))
        }

        status = .completed(FallibleData<EvmFeeModule.Transaction>(
                data: transaction, errors: errors, warnings: fallibleGasPrice.warnings
        ))
    }

    private func transactionSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.Transaction> {
        adjustedTransactionDataSingle(gasPrice: gasPrice, transactionData: transactionData).flatMap { [unowned self] transactionData in
            gasDataService.gasDataSingle(gasPrice: gasPrice, transactionData: transactionData).map { [unowned self] estimatedGasData in
                EvmFeeModule.Transaction(
                        transactionData: transactionData,
                        gasData: estimatedGasData
                )
            }
        }
    }

    private func adjustedTransactionDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<TransactionData> {
        if transactionData.input.isEmpty && transactionData.value == evmBalance {
            let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: Data())

            return gasDataService.gasDataSingle(gasPrice: gasPrice, transactionData: stubTransactionData).flatMap { [unowned self] estimatedGasData in
                let adjustedValue = transactionData.value - estimatedGasData.fee

                if adjustedValue <= 0 {
                    return Single.error(EvmFeeModule.GasDataError.insufficientBalance)
                } else {
                    let adjustedTransactionData = TransactionData(to: transactionData.to, value: adjustedValue, input: transactionData.input)
                    return Single.just(adjustedTransactionData)
                }
            }
        } else {
            return Single.just(transactionData)
        }
    }

}

extension EvmFeeService: IEvmFeeService {

    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> {
        transactionStatusRelay.asObservable()
    }

}
