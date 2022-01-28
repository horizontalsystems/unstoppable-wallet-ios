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

class OneInchFeeService {
    private static let retryInterval = 3
    private var gasPriceDisposeBag = DisposeBag()
    private var disposeBag = DisposeBag()
    private var retryDisposeBag = DisposeBag()

    private static let gasLimitSurchargePercent = 25

    private let provider: OneInchProvider
    private let gasPriceService: LegacyGasPriceService
    private(set) var parameters: OneInchSwapParameters

    private let transactionStatusRelay = PublishRelay<DataStatus<EvmFeeModule.Transaction>>()
    private(set) var status: DataStatus<EvmFeeModule.Transaction> = .failed(EvmFeeModule.GasDataError.noTransactionData) {
        didSet {
            transactionStatusRelay.accept(status)
        }
    }

    var amountTo: Decimal?

    init(provider: OneInchProvider, gasPriceService: LegacyGasPriceService, parameters: OneInchSwapParameters) {
        self.provider = provider
        self.gasPriceService = gasPriceService
        self.parameters = parameters

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
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

        let recipient: EthereumKit.Address? = parameters.recipient.flatMap { try? EthereumKit.Address(hex: $0.raw) }

        provider.swapSingle(platformCoinFrom: parameters.platformCoinFrom,
                        platformCoinTo: parameters.platformCoinTo,
                        amount: parameters.amountFrom,
                        recipient: recipient,
                        slippage: parameters.slippage,
                        gasPrice: gasPriceService.gasPrice.max
                )
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

        status = .failed(error.convertedError)
    }

    private func sync(swap: OneInchKit.Swap) {
        let tx = swap.transaction
        let gasData = EvmFeeModule.GasData(
                gasLimit: surchargedGasLimit(gasLimit: surchargedGasLimit(gasLimit: tx.gasLimit)),
                gasPrice: gasPriceService.gasPrice
        )

        parameters.amountTo = swap.amountOut ?? 0
        let transactionData = EthereumKit.TransactionData(to: tx.to, value: tx.value, input: tx.data)

        status = .completed(EvmFeeModule.Transaction(transactionData: transactionData, gasData: gasData))
    }

    private func surchargedGasLimit(gasLimit: Int) -> Int {
        gasLimit * (100 + Self.gasLimitSurchargePercent) / 100
    }

}

extension OneInchFeeService: IEvmFeeService {

    var statusObservable: Observable<DataStatus<EvmFeeModule.Transaction>> {
        transactionStatusRelay.asObservable()
    }

    var hasEstimatedFee: Bool {
        Self.gasLimitSurchargePercent != 0
    }

}