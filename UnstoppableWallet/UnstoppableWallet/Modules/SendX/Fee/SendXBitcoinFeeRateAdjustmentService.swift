import Foundation
import RxSwift
import RxCocoa

class SendXBitcoinFeeRateAdjustmentService {
    private static let allowedCurrencyCodes = ["USD", "EUR"]
    private static let fallbackCoefficient = 1.1
    private let rules: [Range<Decimal>: Double] = [
        10000..<Decimal.greatestFiniteMagnitude: 1.25,
        5000..<10000: 1.20,
        1000..<5000: 1.15,
        500..<1000: 1.10,
        0..<500: 1.05
    ]

    private let disposeBag = DisposeBag()
    private var availableBalanceDisposeBag = DisposeBag()

    private let feeRateProvider: IFeeRateProvider
    private let coinService: CoinService

    private let amountInputService: IAmountInputService
    weak var availableBalanceService: IAvailableBalanceService?

    private let feeRateUpdatedRelay = PublishRelay<()>()

    init(amountInputService: IAmountInputService, coinService: CoinService, feeRateProvider: IFeeRateProvider) {
        self.amountInputService = amountInputService
        self.coinService = coinService
        self.feeRateProvider = feeRateProvider

        subscribe(disposeBag, amountInputService.amountObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        feeRateUpdatedRelay.accept(())
    }

    private var adjustRatio: Double? {
        guard let rate = coinService.rate,
              Self.allowedCurrencyCodes.contains(rate.currency.code),
              let availableBalance = availableBalanceService?.availableBalance.data else {
            return Self.fallbackCoefficient
        }

        let coinAmount = amountInputService.amount.isZero ? availableBalance : amountInputService.amount
        let fiatAmount = coinAmount * rate.value

        return rules
                .first { key, _  in key.contains(fiatAmount) }?
                .value ?? Self.fallbackCoefficient
    }

}

extension SendXBitcoinFeeRateAdjustmentService: IFeeRateProvider {

    var feeRatePriorityList: [FeeRatePriority] {
        feeRateProvider.feeRatePriorityList
    }

    var defaultFeeRatePriority: FeeRatePriority {
        feeRateProvider.defaultFeeRatePriority
    }

    var recommendedFeeRate: Single<Int> {
        feeRateProvider.recommendedFeeRate
    }

    func feeRate(priority: FeeRatePriority) -> Single<Int> {
        feeRateProvider
                .feeRate(priority: priority)
                .map { [weak self] feeRate -> Int in
                    switch priority {
                    case .custom: return feeRate
                    default:
                        let ratio = self?.adjustRatio ?? Self.fallbackCoefficient
                        let feeRate = Int((Double(feeRate) * ratio).rounded())
                        return feeRate
                    }
                }
    }

    var feeRateUpdatedObservable: Observable<()> {
        feeRateUpdatedRelay.asObservable()
    }

}
