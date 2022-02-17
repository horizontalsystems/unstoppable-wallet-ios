import EthereumKit
import MarketKit
import BigInt
import RxSwift
import RxRelay

class EvmFeeService {
    private let evmKit: EthereumKit.Kit
    private let gasPriceService: IGasPriceService

    private var transactionData: TransactionData
    private let gasLimit: Int?
    let gasLimitSurchargePercent: Int

    private let transactionStatusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.Transaction>>>()
    private(set) var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> = .loading {
        didSet {
            transactionStatusRelay.accept(status)
        }
    }

    private var disposeBag = DisposeBag()
    private var gasPriceDisposeBag = DisposeBag()

    init(evmKit: EthereumKit.Kit, gasPriceService: IGasPriceService, transactionData: TransactionData, gasLimit: Int? = nil, gasLimitSurchargePercent: Int = 0) {
        self.evmKit = evmKit
        self.gasPriceService = gasPriceService
        self.transactionData = transactionData
        self.gasLimit = gasLimit
        self.gasLimitSurchargePercent = gasLimitSurchargePercent

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
    }

    private func gasLimitSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<Int> {
        evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>) {
        switch gasPriceStatus {
        case .loading: status = .loading
        case .failed(let error): status = .failed(error)
        case .completed(let fallibleGasPrice): sync(fallibleGasPrice: fallibleGasPrice)
        }
    }

    private func sync(fallibleGasPrice: FallibleData<GasPrice>) {
        if let gasLimit = gasLimit {
            let transaction = EvmFeeModule.Transaction(
                    transactionData: transactionData,
                    gasData: EvmFeeModule.GasData(gasLimit: gasLimit, gasPrice: fallibleGasPrice.data)
            )

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

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }

    private func transactionSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.Transaction> {
        adjustedTransactionDataSingle(gasPrice: gasPrice, transactionData: transactionData).flatMap { [unowned self] transactionData in
            gasLimitSingle(gasPrice: gasPrice, transactionData: transactionData).map { [unowned self] estimatedGasLimit in
                let gasLimit = surchargedGasLimit(estimatedGasLimit: estimatedGasLimit)

                return EvmFeeModule.Transaction(
                        transactionData: transactionData,
                        gasData: EvmFeeModule.GasData(gasLimit: gasLimit, gasPrice: gasPrice)
                )
            }
        }
    }

    private func adjustedTransactionDataSingle(gasPrice: GasPrice, transactionData: TransactionData) -> Single<TransactionData> {
        if transactionData.input.isEmpty && transactionData.value == evmBalance {
            let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: Data())

            return gasLimitSingle(gasPrice: gasPrice, transactionData: stubTransactionData).flatMap { [unowned self] estimatedGasLimit in
                let gasLimit = surchargedGasLimit(estimatedGasLimit: estimatedGasLimit)
                let adjustedValue = transactionData.value - BigUInt(gasLimit) * BigUInt(gasPrice.max)

                if adjustedValue <= 0 {
                    return Single.error(EvmFeeModule.GasDataError.insufficientBalance)
                } else {
                    let adjustedTransactionData = TransactionData(to: transactionData.to, value: adjustedValue, input: Data())
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
