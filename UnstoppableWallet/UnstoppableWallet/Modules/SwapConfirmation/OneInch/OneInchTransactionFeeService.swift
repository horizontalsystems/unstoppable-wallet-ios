import Foundation
import MarketKit
import RxSwift
import RxRelay
import EthereumKit
import OneInchKit

struct OneInchSwapParameters: Equatable {
    let platformCoinFrom: PlatformCoin
    let platformCoinTo: PlatformCoin
    let amountFrom: Decimal
    var amountTo: Decimal
    let slippage: Decimal
    let recipient: Address?

    static func ==(lhs: OneInchSwapParameters, rhs: OneInchSwapParameters) -> Bool {
        lhs.platformCoinFrom == rhs.platformCoinFrom &&
        lhs.platformCoinTo == rhs.platformCoinTo &&
        lhs.amountFrom == rhs.amountFrom &&
        lhs.amountTo == rhs.amountTo &&
        lhs.slippage == rhs.slippage &&
        lhs.recipient == rhs.recipient
    }

}

class OneInchTransactionFeeService {
    private static let retryInterval = 3
    private var disposeBag = DisposeBag()
    private var retryDisposeBag = DisposeBag()

    private static let gasLimitSurchargePercent = 25

    private let provider: OneInchProvider
    private(set) var parameters: OneInchSwapParameters
    private let feeRateProvider: ICustomRangedFeeRateProvider

    private let transactionStatusRelay = PublishRelay<DataStatus<EvmTransactionService.Transaction>>()
    private(set) var transactionStatus: DataStatus<EvmTransactionService.Transaction> = .failed(EvmTransactionService.GasDataError.noTransactionData) {
        didSet {
            transactionStatusRelay.accept(transactionStatus)
        }
    }

    private let gasPriceTypeRelay = PublishRelay<EvmTransactionService.GasPriceType>()
    private(set) var gasPriceType: EvmTransactionService.GasPriceType = .recommended {
        didSet {
            gasPriceTypeRelay.accept(gasPriceType)
        }
    }

    var amountTo: Decimal?

    private var recommendedGasPrice: Int?
    private let warningOfStuckRelay = PublishRelay<Bool>()

    init(provider: OneInchProvider, parameters: OneInchSwapParameters, feeRateProvider: ICustomRangedFeeRateProvider) {
        self.provider = provider
        self.parameters = parameters
        self.feeRateProvider = feeRateProvider

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        transactionStatus = .loading

        let recipient: EthereumKit.Address? = parameters.recipient.flatMap { try? EthereumKit.Address(hex: $0.raw) }

        gasPriceSingle(gasPriceType: gasPriceType).flatMap { [unowned self] gasPrice -> Single<OneInchKit.Swap> in
                    provider.swapSingle(platformCoinFrom: parameters.platformCoinFrom,
                            platformCoinTo: parameters.platformCoinTo,
                            amount: parameters.amountFrom,
                            recipient: recipient,
                            slippage: parameters.slippage,
                            gasPrice: gasPrice
                    )
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .subscribe(onSuccess: { [weak self] swap in
            self?.sync(swap: swap)
        }, onError: { [weak self] error in
            self?.onSwap(error: error)
        })
        .disposed(by: disposeBag)
    }

    private func onSwap(error: Error) {
        parameters.amountTo = 0

        if let error = error as? OneInchKit.Kit.SwapError, error == .cannotEstimate {       // retry request fee every 5 seconds if cannot estimate
            let retryTimer = Observable.just(()).delay(.seconds(Self.retryInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

            subscribe(retryDisposeBag, retryTimer) { [weak self] in
                self?.retryDisposeBag = DisposeBag()

                self?.sync()
            }
        }

        transactionStatus = .failed(error.convertedError)
    }

    private func sync(swap: OneInchKit.Swap) {
        let tx = swap.transaction
        let gasData = EvmTransactionService.GasData(
                estimatedGasLimit: tx.gasLimit,
                gasLimit: surchargedGasLimit(gasLimit: surchargedGasLimit(gasLimit: tx.gasLimit)),
                gasPrice: tx.gasPrice)

        if case .recommended = gasPriceType {
            recommendedGasPrice = tx.gasPrice
        }

        parameters.amountTo = swap.amountOut ?? 0
        let transactionData = EthereumKit.TransactionData(to: tx.to, value: tx.value, input: tx.data)

        transactionStatus = .completed(EvmTransactionService.Transaction(transactionData: transactionData, gasData: gasData))
    }

    private func surchargedGasLimit(gasLimit: Int) -> Int {
        gasLimit * (100 + Self.gasLimitSurchargePercent) / 100
    }

    private func gasPriceSingle(gasPriceType: EvmTransactionService.GasPriceType) -> Single<Int?> {
        var recommendedSingle: Single<Int?> = feeRateProvider.feeRate(priority: .recommended).map { [weak self] in
            self?.recommendedGasPrice = $0
            return $0
        }

        switch gasPriceType {
        case .recommended:
            warningOfStuckRelay.accept(false)
            return recommendedSingle
        case .custom(let gasPrice):
            if let recommendedGasPrice = recommendedGasPrice {
                recommendedSingle = .just(recommendedGasPrice)
            }

            return recommendedSingle.map { [weak self] recommendedGasPrice in
                self?.warningOfStuckRelay.accept(gasPrice < (recommendedGasPrice ?? 0))
                return gasPrice
            }
        }
    }

}

extension OneInchTransactionFeeService: IEvmTransactionFeeService {

    var customFeeRange: ClosedRange<Int> {
        feeRateProvider.customFeeRange
    }

    func set(transactionData: TransactionData?) {

    }

    func set(gasPriceType: EvmTransactionService.GasPriceType) {
        self.gasPriceType = gasPriceType

        sync()
    }

    var transactionStatusObservable: Observable<DataStatus<EvmTransactionService.Transaction>> {
        transactionStatusRelay.asObservable()
    }

    var hasEstimatedFee: Bool {
        Self.gasLimitSurchargePercent != 0
    }

    var gasPriceTypeObservable: Observable<EvmTransactionService.GasPriceType> {
        gasPriceTypeRelay.asObservable()
    }

    var warningOfStuckObservable: Observable<Bool> {
        warningOfStuckRelay.asObservable()
    }

}