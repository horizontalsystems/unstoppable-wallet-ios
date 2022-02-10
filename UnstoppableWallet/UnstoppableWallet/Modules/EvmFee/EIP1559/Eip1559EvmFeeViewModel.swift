import RxSwift
import RxRelay
import RxCocoa
import EthereumKit

class Eip1559EvmFeeViewModel {
    private let disposeBag = DisposeBag()

    private let gasPriceService: Eip1559GasPriceService
    private let feeService: IEvmFeeService
    private let coinService: CoinService
    private let cautionsFactory: SendEvmCautionsFactory

    private let resetButtonActiveRelay = BehaviorRelay<Bool>(value: false)
    private let maxFeeRelay = BehaviorRelay<String?>(value: nil)
    private let gasLimitRelay = BehaviorRelay<String>(value: "n/a")
    private let currentBaseFeeRelay = BehaviorRelay<String>(value: "n/a")
    private let baseFeeRelay = BehaviorRelay<String>(value: "n/a")
    private let tipsRelay = BehaviorRelay<String>(value: "n/a")
    private let baseFeeSliderRelay = BehaviorRelay<FeeSliderViewItem?>(value: nil)
    private let tipsSliderRelay = BehaviorRelay<FeeSliderViewItem?>(value: nil)
    private let cautionsRelay = BehaviorRelay<[TitledCaution]>(value: [])

    init(gasPriceService: Eip1559GasPriceService, feeService: IEvmFeeService, coinService: CoinService, cautionsFactory: SendEvmCautionsFactory) {
        self.gasPriceService = gasPriceService
        self.feeService = feeService
        self.coinService = coinService
        self.cautionsFactory = cautionsFactory

        sync(transactionStatus: feeService.status)
        sync(gasPriceStatus: gasPriceService.status)
        sync(recommendedBaseFee: gasPriceService.recommendedBaseFee)

        subscribe(disposeBag, feeService.statusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        subscribe(disposeBag, gasPriceService.statusObservable) { [weak self] in self?.sync(gasPriceStatus: $0) }
        subscribe(disposeBag, gasPriceService.recommendedBaseFeeObservable) { [weak self] in self?.sync(recommendedBaseFee: $0) }
        subscribe(disposeBag, gasPriceService.baseFeeRangeChangedObservable) { [weak self] in self?.sync(gasPriceStatus: nil) }
        subscribe(disposeBag, gasPriceService.tipsRangeChangedObservable) { [weak self] in self?.sync(gasPriceStatus: nil) }
    }

    private func sync(transactionStatus: DataStatus<FallibleData<EvmFeeModule.Transaction>>) {
        let maxFeeStatus: String
        let gasLimit: String
        let cautions: [TitledCaution]

        switch transactionStatus {
        case .loading:
            maxFeeStatus = "action.loading".localized
            gasLimit = "n/a".localized
            cautions = []
        case .failed(let error):
            maxFeeStatus = "n/a".localized
            gasLimit = "n/a".localized
            cautions = cautionsFactory.items(errors: [error], warnings: [], baseCoinService: coinService)
        case .completed(let fallibleTransaction):
            let gasData = fallibleTransaction.data.gasData

            maxFeeStatus = coinService.amountData(value: gasData.fee).formattedString
            gasLimit = gasData.gasLimit.description
            cautions = cautionsFactory.items(errors: fallibleTransaction.errors, warnings: fallibleTransaction.warnings, baseCoinService: coinService)
        }

        maxFeeRelay.accept(maxFeeStatus)
        gasLimitRelay.accept(gasLimit)
        cautionsRelay.accept(cautions)
    }

    private func sync(gasPriceStatus: DataStatus<FallibleData<GasPrice>>?) {
        let gasPriceStatus = gasPriceStatus ?? gasPriceService.status

        guard case .completed = gasPriceStatus else {
            baseFeeRelay.accept("n/a")
            tipsRelay.accept("n/a")
            baseFeeSliderRelay.accept(nil)
            tipsSliderRelay.accept(nil)
            return
        }

        let gweiBaseFee = gwei(wei: gasPriceService.baseFee)
        baseFeeRelay.accept("\(gweiBaseFee) gwei")
        baseFeeSliderRelay.accept(FeeSliderViewItem(initialValue: gweiBaseFee, range: gwei(range: gasPriceService.baseFeeRange)))

        let gweiTips = gwei(wei: gasPriceService.tips)
        tipsRelay.accept("\(gweiTips) gwei")
        tipsSliderRelay.accept(FeeSliderViewItem(initialValue: gweiTips, range: gwei(range: gasPriceService.tipsRange)))
    }

    private func sync(recommendedBaseFee: Int) {
        currentBaseFeeRelay.accept("\(gwei(wei: recommendedBaseFee)) gwei")
    }

    private func gwei(wei: Int) -> Int {
        wei / 1_000_000_000
    }

    private func gwei(range: ClosedRange<Int>) -> ClosedRange<Int> {
        gwei(wei: range.lowerBound)...gwei(wei: range.upperBound)
    }

    private func wei(gwei: Int) -> Int {
        gwei * 1_000_000_000
    }

}

extension Eip1559EvmFeeViewModel {

    var gasLimitDriver: Driver<String> {
        gasLimitRelay.asDriver()
    }

    var currentBaseFeeDriver: Driver<String> {
        currentBaseFeeRelay.asDriver()
    }

    var baseFeeDriver: Driver<String> {
        baseFeeRelay.asDriver()
    }

    var tipsDriver: Driver<String> {
        tipsRelay.asDriver()
    }

    var baseFeeSliderDriver: Driver<FeeSliderViewItem?> {
        baseFeeSliderRelay.asDriver()
    }

    var tipsSliderDriver: Driver<FeeSliderViewItem?> {
        tipsSliderRelay.asDriver()
    }

    var cautionsDriver: Driver<[TitledCaution]> {
        cautionsRelay.asDriver()
    }

    var resetButtonActiveDriver: Driver<Bool> {
        resetButtonActiveRelay.asDriver()
    }

    func set(baseFee: Int) {
        gasPriceService.set(baseFee: wei(gwei: baseFee))
        resetButtonActiveRelay.accept(true)
    }

    func set(tips: Int) {
        gasPriceService.set(tips: wei(gwei: tips))
        resetButtonActiveRelay.accept(true)
    }

    func reset() {
        gasPriceService.setRecommendedGasPrice()
        resetButtonActiveRelay.accept(false)
    }

}

extension Eip1559EvmFeeViewModel: IFeeViewModel {

    var maxFeeDriver: Driver<String?> {
        maxFeeRelay.asDriver()
    }

    var editButtonVisibleDriver: Driver<Bool> {
        Single<Bool>.just(false).asDriver(onErrorJustReturn: false)
    }

}
