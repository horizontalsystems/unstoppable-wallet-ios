import Foundation
import MarketKit
import RxSwift
import RxRelay
import EvmKit
import OneInchKit
import BigInt

struct OneInchSwapParameters: Equatable {
    let tokenFrom: MarketKit.Token
    let tokenTo: MarketKit.Token
    let amountFrom: Decimal
    var amountTo: Decimal
    let slippage: Decimal
    let recipient: Address?

    static func ==(lhs: OneInchSwapParameters, rhs: OneInchSwapParameters) -> Bool {
        lhs.tokenFrom == rhs.tokenFrom &&
        lhs.tokenTo == rhs.tokenTo &&
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

    private let evmKit: EvmKit.Kit
    private let provider: OneInchProvider
    private let gasPriceService: IGasPriceService
    private(set) var parameters: OneInchSwapParameters

    private let transactionStatusRelay = PublishRelay<DataStatus<FallibleData<EvmFeeModule.Transaction>>>()
    private(set) var status: DataStatus<FallibleData<EvmFeeModule.Transaction>> = .loading {
        didSet {
            transactionStatusRelay.accept(status)
        }
    }

    var amountTo: Decimal?

    init(evmKit: EvmKit.Kit, provider: OneInchProvider, gasPriceService: IGasPriceService, parameters: OneInchSwapParameters) {
        self.evmKit = evmKit
        self.provider = provider
        self.gasPriceService = gasPriceService
        self.parameters = parameters

        sync(gasPriceStatus: gasPriceService.status)
        subscribe(gasPriceDisposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
    }

    private var evmBalance: BigUInt {
        evmKit.accountState?.balance ?? 0
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>) {
        switch gasPriceStatus {
        case .loading: status = .loading
        case .failed(let error): status = .failed(error)
        case .completed(let fallibleGasPrice): sync(fallibleGasPrice: fallibleGasPrice)
        }
    }

    private func sync(fallibleGasPrice: FallibleData<GasPrice>) {
        disposeBag = DisposeBag()

        let recipient: EvmKit.Address? = parameters.recipient.flatMap { try? EvmKit.Address(hex: $0.raw) }

        provider.swapSingle(
                        tokenFrom: parameters.tokenFrom,
                        tokenTo: parameters.tokenTo,
                        amount: parameters.amountFrom,
                        recipient: recipient,
                        slippage: parameters.slippage,
                        gasPrice: fallibleGasPrice.data
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] swap in
                    self?.sync(swap: swap, fallibleGasPrice: fallibleGasPrice)
                }, onError: { [weak self] error in
                    self?.onSwap(error: error, fallibleGasPrice: fallibleGasPrice)
                })
                .disposed(by: disposeBag)
    }

    private func onSwap(error: Error, fallibleGasPrice: FallibleData<GasPrice>) {
        parameters.amountTo = 0

        if let error = error as? OneInchKit.Kit.SwapError, error == .cannotEstimate {       // retry request fee every 5 seconds if cannot estimate
            let retryTimer = Observable.just(()).delay(.seconds(Self.retryInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

            subscribe(retryDisposeBag, retryTimer) { [weak self] in
                self?.retryDisposeBag = DisposeBag()

                self?.sync(fallibleGasPrice: fallibleGasPrice)
            }
        }

        status = .failed(error.convertedError)
    }

    private func sync(swap: OneInchKit.Swap, fallibleGasPrice: FallibleData<GasPrice>) {
        let tx = swap.transaction
        let gasData = EvmFeeModule.GasData(
                limit: surchargedGasLimit(gasLimit: surchargedGasLimit(gasLimit: tx.gasLimit)),
                price: fallibleGasPrice.data
        )

        parameters.amountTo = swap.amountOut ?? 0
        let transactionData = EvmKit.TransactionData(to: tx.to, value: tx.value, input: tx.data)
        let totalAmount = transactionData.value + gasData.fee
        var errors: [Error] = fallibleGasPrice.errors

        if totalAmount > evmBalance {
            errors.append(SendEvmTransactionService.TransactionError.insufficientBalance(requiredBalance: totalAmount))
        }

        status = .completed(FallibleData<EvmFeeModule.Transaction>(
                data: EvmFeeModule.Transaction(transactionData: transactionData, gasData: gasData),
                errors: errors,
                warnings: fallibleGasPrice.warnings
        ))
    }

    private func surchargedGasLimit(gasLimit: Int) -> Int {
        gasLimit * (100 + Self.gasLimitSurchargePercent) / 100
    }

}

extension OneInchFeeService: IEvmFeeService {

    var statusObservable: Observable<DataStatus<FallibleData<EvmFeeModule.Transaction>>> {
        transactionStatusRelay.asObservable()
    }

    var hasEstimatedFee: Bool {
        Self.gasLimitSurchargePercent != 0
    }

}
