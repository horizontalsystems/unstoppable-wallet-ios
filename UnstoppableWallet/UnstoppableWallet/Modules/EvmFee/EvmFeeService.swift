import EthereumKit
import MarketKit
import BigInt
import RxSwift
import RxRelay

class EvmFeeService {
    private let evmKit: EthereumKit.Kit
    private let gasPriceService: LegacyGasPriceService

    private var transactionData: TransactionData
    let gasLimitSurchargePercent: Int

    private let transactionStatusRelay = PublishRelay<DataStatus<EvmFeeModule.Transaction>>()
    private(set) var status: DataStatus<EvmFeeModule.Transaction> = .failed(EvmFeeModule.GasDataError.noTransactionData) {
        didSet {
            transactionStatusRelay.accept(status)
        }
    }

    private var disposeBag = DisposeBag()
    private var gasPriceDisposeBag = DisposeBag()

    init(evmKit: EthereumKit.Kit, gasPriceService: LegacyGasPriceService, transactionData: TransactionData, gasLimitSurchargePercent: Int = 0) {
        self.evmKit = evmKit
        self.gasPriceService = gasPriceService
        self.transactionData = transactionData
        self.gasLimitSurchargePercent = gasLimitSurchargePercent

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
    }

    private func gasLimitSingle(gasPrice: EvmFeeModule.GasPrice, transactionData: TransactionData) -> Single<Int> {
        evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice.max) // TODO: estimateGas must accept GasPrice enum
    }

    private func sync(gasPriceStatus: DataStatus<EvmFeeModule.GasPrice>) {
        switch gasPriceStatus {
        case .loading: status = .loading
        case .failed(let error): status = .failed(error)
        case .completed(let gasPrice): sync()
        }
    }

    private func sync() {
        disposeBag = DisposeBag()

        status = .loading

        transactionSingle(gasPrice: gasPriceService.gasPrice, transactionData: transactionData)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] transaction in
                    self?.status = .completed(transaction)
                }, onError: { [weak self] error in
                    self?.status = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }

    private func transactionSingle(gasPrice: EvmFeeModule.GasPrice, transactionData: TransactionData) -> Single<EvmFeeModule.Transaction> {
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

    private func adjustedTransactionDataSingle(gasPrice: EvmFeeModule.GasPrice, transactionData: TransactionData) -> Single<TransactionData> {
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

    var statusObservable: Observable<DataStatus<EvmFeeModule.Transaction>> {
        transactionStatusRelay.asObservable()
    }

}
