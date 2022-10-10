import BigInt
import EvmKit
import MarketKit
import RxRelay
import RxSwift

class EvmFeeService {
    private let evmKit: EvmKit.Kit
    private let gasPriceService: IGasPriceService
    private let gasDataService: EvmCommonGasDataService

    private var transactionData: TransactionData

    private let transactionStatusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.Transaction>>>()
    private(set) var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> = .loading {
        didSet {
            transactionStatusRelay.accept(status)
        }
    }

    private var disposeBag = DisposeBag()
    private var gasPriceDisposeBag = DisposeBag()

    init(evmKit: EvmKit.Kit, gasPriceService: IGasPriceService, gasDataService: EvmCommonGasDataService, transactionData: TransactionData) {
        self.evmKit = evmKit
        self.gasPriceService = gasPriceService
        self.gasDataService = gasDataService
        self.transactionData = transactionData

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in
            self?.sync(gasPriceStatus: $0)
        }
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>) {
        switch gasPriceStatus {
        case .loading: status = .loading
        case let .failed(error): status = .failed(error)
        case let .completed(fallibleGasPrice): sync(fallibleGasPrice: fallibleGasPrice)
        }
    }

    private func sync(fallibleGasPrice: FallibleData<GasPrice>) {
        let single: Single<EvmFeeModule.Transaction>
        let transactionData = transactionData

        if let transactionSingle = gasDataService.predefinedGasData(gasPrice: fallibleGasPrice.data, transactionData: transactionData) {
            // transaction comes with predefined gasLimit
            single = transactionSingle
                .map {
                    EvmFeeModule.Transaction(transactionData: transactionData, gasData: $0)
                }
        } else if transactionData.input.isEmpty, transactionData.value == evmBalance {
            // If try to send native token (input is empty) and max value, we must calculate fee and decrease maximum value by that fee
            single = gasDataService
                .gasDataSingle(gasPrice: fallibleGasPrice.data, transactionData: transactionData, stubAmount: 1)
                .flatMap { adjustedGasData in
                    let adjustedValue = transactionData.value - adjustedGasData.fee

                    if adjustedValue <= 0 {
                        return Single.error(EvmFeeModule.GasDataError.insufficientBalance)
                    } else {
                        let adjustedTransactionData = TransactionData(to: transactionData.to, value: adjustedValue, input: transactionData.input)
                        return Single.just(EvmFeeModule.Transaction(transactionData: adjustedTransactionData, gasData: adjustedGasData))
                    }
                }
        } else {
            // transaction for tokens
            single = gasDataService
                .gasDataSingle(gasPrice: fallibleGasPrice.data, transactionData: transactionData)
                .map {
                    EvmFeeModule.Transaction(transactionData: transactionData, gasData: $0)
                }
        }

        disposeBag = DisposeBag()
        single
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] transaction in
                self?.syncStatus(fallibleGasPrice: fallibleGasPrice, transaction: transaction)
            }, onError: { error in
                self.status = .failed(error)
            })
            .disposed(by: disposeBag)
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func syncStatus(fallibleGasPrice: FallibleData<GasPrice>, transaction: EvmFeeModule.Transaction) {
        var errors: [Error] = fallibleGasPrice.errors

        let totalAmount = transaction.transactionData.value + transaction.gasData.fee
        if totalAmount > evmBalance {
            errors.append(SendEvmTransactionService.TransactionError.insufficientBalance(requiredBalance: totalAmount))
        }

        status = .completed(FallibleData<EvmFeeModule.Transaction>(
            data: transaction, errors: errors, warnings: fallibleGasPrice.warnings
        ))
    }
}

extension EvmFeeService: IEvmFeeService {
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> {
        transactionStatusRelay.asObservable()
    }
}
