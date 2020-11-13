import EthereumKit
import BigInt
import RxSwift
import RxRelay

class EthereumTransactionService {
    private let ethereumKit: Kit
    private let feeRateProvider: EthereumFeeRateProvider

    private var transactionData: TransactionData?

    private(set) var gasPriceType: GasPriceType = .recommended {
        didSet {
            gasPriceTypeRelay.accept(gasPriceType)
        }
    }
    private let gasPriceTypeRelay = PublishRelay<GasPriceType>()

    private(set) var transactionStatus: DataStatus<Transaction> = .failed(GasDataError.noTransactionData) {
        didSet {
            transactionStatusRelay.accept(transactionStatus)
        }
    }
    private let transactionStatusRelay = PublishRelay<DataStatus<Transaction>>()

    private var disposeBag = DisposeBag()

    init(ethereumKit: Kit, feeRateProvider: EthereumFeeRateProvider) {
        self.ethereumKit = ethereumKit
        self.feeRateProvider = feeRateProvider
    }

    private func gasPriceSingle(gasPriceType: GasPriceType) -> Single<Int> {
        switch gasPriceType {
        case .recommended:
            return feeRateProvider.feeRate
                    .map { rate in
                        rate.feeRate(priority: .recommended)
                    }
        case .custom(let gasPrice):
            return Single.just(gasPrice)
        }
    }

    private func gasLimitSingle(gasPrice: Int, transactionData: TransactionData) -> Single<Int> {
        ethereumKit.estimateGas(to: transactionData.to, amount: transactionData.value, gasPrice: gasPrice, data: transactionData.input)
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
                    gasLimitSingle(gasPrice: gasPrice, transactionData: transactionData)
                            .map { gasLimit -> Transaction in
                                Transaction(
                                        data: transactionData,
                                        gasData: GasData(gasLimit: gasLimit, gasPrice: gasPrice)
                                )
                            }
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] transaction in
                    self?.transactionStatus = .completed(transaction)
                }, onError: { [weak self] error in
                     self?.transactionStatus = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension EthereumTransactionService {

    var gasPriceTypeObservable: Observable<GasPriceType> {
        gasPriceTypeRelay.asObservable()
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

    func resync() {
        sync()
    }

}

extension EthereumTransactionService {

    struct TransactionData {
        var to: Address
        var value: BigUInt
        var input: Data
    }

    struct GasData {
        let gasLimit: Int
        let gasPrice: Int

        var fee: BigUInt {
            BigUInt(gasLimit * gasPrice)
        }
    }

    struct Transaction {
        let data: TransactionData
        let gasData: GasData

        var totalAmount: BigUInt {
            data.value + gasData.fee
        }
    }

    enum GasPriceType {
        case recommended
        case custom(gasPrice: Int)
    }

    enum GasDataError: Error {
        case noTransactionData
    }

}
