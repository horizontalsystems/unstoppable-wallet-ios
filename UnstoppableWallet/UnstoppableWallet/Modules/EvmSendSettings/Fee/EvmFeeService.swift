import BigInt
import EvmKit
import MarketKit
import RxRelay
import RxSwift

class EvmFeeService {
    let gasPriceService: IGasPriceService
    let coinService: CoinService

    private let evmKit: EvmKit.Kit
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

    init(evmKit: EvmKit.Kit, gasPriceService: IGasPriceService, gasDataService: EvmCommonGasDataService, coinService: CoinService, transactionData: TransactionData) {
        self.evmKit = evmKit
        self.gasPriceService = gasPriceService
        self.gasDataService = gasDataService
        self.coinService = coinService
        self.transactionData = transactionData

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in
            self?.sync(gasPriceStatus: $0)
        }
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<EvmFeeModule.GasPrices>>) {
        switch gasPriceStatus {
        case .loading: status = .loading
        case let .failed(error): status = .failed(error)
        case let .completed(fallibleGasPrices): sync(fallibleGasPrices: fallibleGasPrices)
        }
    }

    private func sync(fallibleGasPrices: FallibleData<EvmFeeModule.GasPrices>) {
        disposeBag = DisposeBag()
        let single: Single<EvmFeeModule.Transaction>
        let transactionData = transactionData

        if transactionData.input.isEmpty, transactionData.value == evmBalance {
            // If try to send native token (input is empty) and max value, we must calculate fee and decrease maximum value by that fee
            single = gasDataService
                    .gasDataSingle(gasPrice: fallibleGasPrices.data.recommended, transactionData: transactionData, stubAmount: 1)
                    .flatMap { adjustedGasData in
                        adjustedGasData.set(price: fallibleGasPrices.data.userDefined)

                        if transactionData.value <= adjustedGasData.fee {
                            return Single.error(EvmFeeModule.GasDataError.insufficientBalance)
                        } else {
                            let adjustedTransactionData = TransactionData(to: transactionData.to, value: transactionData.value - adjustedGasData.fee, input: transactionData.input)
                            return Single.just(EvmFeeModule.Transaction(transactionData: adjustedTransactionData, gasData: adjustedGasData))
                        }
                    }
        } else {
            single = gasDataService
                    .gasDataSingle(gasPrice: fallibleGasPrices.data.userDefined, transactionData: transactionData)
                    .catchError { [weak self] error in
                        if case AppError.ethereum(reason: let ethereumError) = error.convertedError,
                           case .lowerThanBaseGasLimit = ethereumError,
                           let _self = self {
                            return _self
                                    .gasDataService
                                    .gasDataSingle(gasPrice: fallibleGasPrices.data.recommended, transactionData: transactionData)
                                    .map { gasData in
                                        gasData.set(price: fallibleGasPrices.data.userDefined)
                                        return gasData
                                    }
                        }

                        return .error(error)
                    }
                    .map { EvmFeeModule.Transaction(transactionData: transactionData, gasData: $0) }
        }

        single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] transaction in
                    self?.syncStatus(transaction: transaction, errors: fallibleGasPrices.errors, warnings: fallibleGasPrices.warnings)
                }, onError: { error in
                    self.status = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func syncStatus(transaction: EvmFeeModule.Transaction, errors: [Error], warnings: [Warning]) {
        var errors: [Error] = errors

        let totalAmount = transaction.transactionData.value + transaction.gasData.fee
        if totalAmount > evmBalance {
            errors.append(SendEvmTransactionService.TransactionError.insufficientBalance(requiredBalance: totalAmount))
        }

        status = .completed(FallibleData<EvmFeeModule.Transaction>(
            data: transaction, errors: errors, warnings: warnings
        ))
    }
}

extension EvmFeeService: IEvmFeeService {
    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> {
        transactionStatusRelay.asObservable()
    }
}
