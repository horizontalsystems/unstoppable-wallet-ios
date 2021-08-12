import EthereumKit
import BigInt
import RxSwift
import RxRelay

protocol IEvmTransactionFeeService {
    var customFeeRange: ClosedRange<Int> { get }

    var hasEstimatedFee: Bool { get }
    var transactionStatus: DataStatus<EvmTransactionService.Transaction> { get }
    var transactionStatusObservable: Observable<DataStatus<EvmTransactionService.Transaction>> { get }

    var gasPriceType: EvmTransactionService.GasPriceType { get }
    var gasPriceTypeObservable: Observable<EvmTransactionService.GasPriceType> { get }

    var warningOfStuckObservable: Observable<Bool> { get }

    func set(gasPriceType: EvmTransactionService.GasPriceType)
}

class EvmTransactionService {
    private let evmKit: Kit
    private let feeRateProvider: ICustomRangedFeeRateProvider
    let gasLimitSurchargePercent: Int

    private var transactionData: TransactionData?

    private let gasPriceTypeRelay = PublishRelay<GasPriceType>()
    private(set) var gasPriceType: GasPriceType = .recommended {
        didSet {
            gasPriceTypeRelay.accept(gasPriceType)
        }
    }

    private var recommendedGasPrice: Int?
    private let warningOfStuckRelay = PublishRelay<Bool>()

    private let transactionStatusRelay = PublishRelay<DataStatus<Transaction>>()
    private(set) var transactionStatus: DataStatus<Transaction> = .failed(GasDataError.noTransactionData) {
        didSet {
            transactionStatusRelay.accept(transactionStatus)
        }
    }

    private var disposeBag = DisposeBag()

    init(evmKit: Kit, feeRateProvider: ICustomRangedFeeRateProvider, gasLimitSurchargePercent: Int = 0, customFeeRange: ClosedRange<Int> = 1...400) {
        self.evmKit = evmKit
        self.feeRateProvider = feeRateProvider
        self.gasLimitSurchargePercent = gasLimitSurchargePercent
    }

    private func gasPriceSingle(gasPriceType: GasPriceType) -> Single<Int> {
        var recommendedSingle: Single<Int> = feeRateProvider.feeRate(priority: .recommended)

        switch gasPriceType {
        case .recommended:
            warningOfStuckRelay.accept(false)
            return recommendedSingle
        case .custom(let gasPrice):
            if let recommendedGasPrice = recommendedGasPrice {
                recommendedSingle = .just(recommendedGasPrice)
            }

            return recommendedSingle.map { [weak self] recommendedGasPrice in
                self?.warningOfStuckRelay.accept(gasPrice < recommendedGasPrice)
                return gasPrice
            }
        }
    }

    private func gasLimitSingle(gasPrice: Int, transactionData: TransactionData) -> Single<Int> {
        evmKit.estimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

    private func sync() {
        disposeBag = DisposeBag()

        guard let transactionData = transactionData else {
            transactionStatus = .failed(GasDataError.noTransactionData)
            return
        }

        transactionStatus = .loading

        gasPriceSingle(gasPriceType: gasPriceType)
                .flatMap { [unowned self] gasPrice -> Single<Transaction> in
                    transactionSingle(gasPrice: gasPrice, transactionData: transactionData)
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] transaction in
                    self?.transactionStatus = .completed(transaction)
                }, onError: { [weak self] error in
                     self?.transactionStatus = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }

    private func transactionSingle(gasPrice: Int, transactionData: TransactionData) -> Single<Transaction> {
        adjustedTransactionDataSingle(gasPrice: gasPrice, transactionData: transactionData).flatMap { [unowned self] transactionData in
            gasLimitSingle(gasPrice: gasPrice, transactionData: transactionData).map { [unowned self] estimatedGasLimit in
                let gasLimit = surchargedGasLimit(estimatedGasLimit: estimatedGasLimit)

                return Transaction(
                        transactionData: transactionData,
                        gasData: GasData(estimatedGasLimit: estimatedGasLimit, gasLimit: gasLimit, gasPrice: gasPrice)
                )
            }
        }
    }

    private func adjustedTransactionDataSingle(gasPrice: Int, transactionData: TransactionData) -> Single<TransactionData> {
        if transactionData.input.isEmpty && transactionData.value == evmBalance {
            let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: Data())

            return gasLimitSingle(gasPrice: gasPrice, transactionData: stubTransactionData).flatMap { [unowned self] estimatedGasLimit in
                let gasLimit = surchargedGasLimit(estimatedGasLimit: estimatedGasLimit)
                let adjustedValue = transactionData.value - BigUInt(gasLimit) * BigUInt(gasPrice)

                if adjustedValue <= 0 {
                    return Single.error(GasDataError.insufficientBalance)
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

extension EvmTransactionService: IEvmTransactionFeeService {

    var customFeeRange: ClosedRange<Int> {
        feeRateProvider.customFeeRange
    }

    var hasEstimatedFee: Bool {
        gasLimitSurchargePercent != 0
    }

    var gasPriceTypeObservable: Observable<GasPriceType> {
        gasPriceTypeRelay.asObservable()
    }

    var warningOfStuckObservable: Observable<Bool> {
        warningOfStuckRelay.asObservable()
    }

    var transactionStatusObservable: Observable<DataStatus<Transaction>> {
        transactionStatusRelay.asObservable()
    }

    func set(transactionData: TransactionData?) {
        self.transactionData = transactionData
        sync()
    }

    func set(gasPriceType: GasPriceType) {
        self.gasPriceType = gasPriceType
        sync()
    }

}

extension EvmTransactionService {

    struct GasData {
        let estimatedGasLimit: Int
        let gasLimit: Int
        let gasPrice: Int

        var estimatedFee: BigUInt {
            BigUInt(estimatedGasLimit * gasPrice)
        }

        var fee: BigUInt {
            BigUInt(gasLimit * gasPrice)
        }
    }

    struct Transaction {
        let transactionData: TransactionData
        let gasData: GasData

        var totalAmount: BigUInt {
            transactionData.value + gasData.fee
        }
    }

    enum GasPriceType {
        case recommended
        case custom(gasPrice: Int)
    }

    enum GasDataError: Error {
        case noTransactionData
        case insufficientBalance
    }

}
