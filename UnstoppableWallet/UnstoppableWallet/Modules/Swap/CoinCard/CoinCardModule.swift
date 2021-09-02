import UniswapKit
import RxSwift
import MarketKit

protocol ISwapCoinCardService: AnyObject {
    var dex: SwapModule.Dex { get }
    var readOnly: Bool { get }
    var isEstimated: Bool { get }
    var platformCoin: PlatformCoin? { get }
    var balance: Decimal? { get }
    var amount: Decimal { get }

    var readOnlyObservable: Observable<Bool> { get }
    var isEstimatedObservable: Observable<Bool> { get }
    var platformCoinObservable: Observable<PlatformCoin?> { get }
    var balanceObservable: Observable<Decimal?> { get }
    var errorObservable: Observable<Error?> { get }
    var amountObservable: Observable<Decimal> { get }

    func onChange(platformCoin: PlatformCoin)
}

extension ISwapCoinCardService {

    var readOnly: Bool {
        false
    }

    var readOnlyObservable: Observable<Bool> {
        Observable.just(false)
    }

}

struct CoinCardModule {

    static func fromCell(service: UniswapService, tradeService: UniswapTradeService, switchService: AmountTypeSwitchService) -> SwapCoinCardCell {
        let coinCardService = SwapFromCoinCardService(service: service, tradeService: tradeService)

        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManagerNew)
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let viewModel = SwapCoinCardViewModel(coinCardService: coinCardService, fiatService: fiatService)

        let amountInputViewModel = AmountInputViewModel(
                service: coinCardService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        return SwapCoinCardCell(viewModel: viewModel, amountInputViewModel: amountInputViewModel, title: "swap.you_pay".localized)
    }

    static func toCell(service: UniswapService, tradeService: UniswapTradeService, switchService: AmountTypeSwitchService) -> SwapCoinCardCell {
        let coinCardService = SwapToCoinCardService(service: service, tradeService: tradeService)

        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManagerNew)
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let viewModel = SwapCoinCardViewModel(coinCardService: coinCardService, fiatService: fiatService)

        let amountInputViewModel = AmountInputViewModel(
                service: coinCardService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser(),
                isMaxSupported: false
        )
        return SwapCoinCardCell(viewModel: viewModel, amountInputViewModel: amountInputViewModel, title: "swap.you_get".localized)
    }

    static func fromCell(service: OneInchService, tradeService: OneInchTradeService, switchService: AmountTypeSwitchService) -> SwapCoinCardCell {
        let coinCardService = SwapFromCoinCardOneInchService(service: service, tradeService: tradeService)

        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManagerNew)
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let viewModel = SwapCoinCardViewModel(coinCardService: coinCardService, fiatService: fiatService)

        let amountInputViewModel = AmountInputViewModel(
                service: coinCardService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        return SwapCoinCardCell(viewModel: viewModel, amountInputViewModel: amountInputViewModel, title: "swap.you_pay".localized)
    }

    static func toCell(service: OneInchService, tradeService: OneInchTradeService, switchService: AmountTypeSwitchService) -> SwapCoinCardCell {
        let coinCardService = SwapToCoinCardOneInchService(service: service, tradeService: tradeService)

        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManagerNew)
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let viewModel = SwapCoinCardViewModel(coinCardService: coinCardService, fiatService: fiatService)

        let amountInputViewModel = AmountInputViewModel(
                service: coinCardService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser(),
                isMaxSupported: false
        )
        return SwapCoinCardCell(viewModel: viewModel, amountInputViewModel: amountInputViewModel, title: "swap.you_get".localized)
    }

}

class SwapFromCoinCardService: ISwapCoinCardService, IAmountInputService {
    private let service: UniswapService
    private let tradeService: UniswapTradeService

    init(service: UniswapService, tradeService: UniswapTradeService) {
        self.service = service
        self.tradeService = tradeService
    }

    var dex: SwapModule.Dex { service.dex }
    var isEstimated: Bool { tradeService.tradeType != .exactIn }
    var amount: Decimal { tradeService.amountIn }
    var platformCoin: PlatformCoin? { tradeService.platformCoinIn }
    var balance: Decimal? { service.balanceIn }

    var isEstimatedObservable: Observable<Bool> { tradeService.tradeTypeObservable.map { $0 != .exactIn } }
    var amountObservable: Observable<Decimal> { tradeService.amountInObservable }
    var platformCoinObservable: Observable<PlatformCoin?> { tradeService.platformCoinInObservable }
    var balanceObservable: Observable<Decimal?> { service.balanceInObservable }
    var errorObservable: Observable<Error?> {
        service.errorsObservable.map {
            $0.first(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError })
        }
    }

    func onChange(amount: Decimal) {
        tradeService.set(amountIn: amount)
    }

    func onChange(platformCoin: PlatformCoin) {
        tradeService.set(platformCoinIn: platformCoin)
    }

}

class SwapToCoinCardService: ISwapCoinCardService, IAmountInputService {
    private let service: UniswapService
    private let tradeService: UniswapTradeService

    init(service: UniswapService, tradeService: UniswapTradeService) {
        self.service = service
        self.tradeService = tradeService
    }

    var dex: SwapModule.Dex { service.dex }
    var isEstimated: Bool { tradeService.tradeType != .exactOut }
    var amount: Decimal { tradeService.amountOut }
    var platformCoin: PlatformCoin? { tradeService.platformCoinOut }
    var balance: Decimal? { service.balanceOut }

    var isEstimatedObservable: Observable<Bool> { tradeService.tradeTypeObservable.map { $0 != .exactOut } }
    var amountObservable: Observable<Decimal> { tradeService.amountOutObservable }
    var platformCoinObservable: Observable<PlatformCoin?> { tradeService.platformCoinOutObservable }
    var balanceObservable: Observable<Decimal?> { service.balanceOutObservable }
    var errorObservable: Observable<Error?> {
        Observable<Error?>.just(nil)
    }

    func onChange(amount: Decimal) {
        tradeService.set(amountOut: amount)
    }

    func onChange(platformCoin: PlatformCoin) {
        tradeService.set(platformCoinOut: platformCoin)
    }

}

class SwapFromCoinCardOneInchService: ISwapCoinCardService, IAmountInputService {
    private let service: OneInchService
    private let tradeService: OneInchTradeService

    init(service: OneInchService, tradeService: OneInchTradeService) {
        self.service = service
        self.tradeService = tradeService
    }

    var dex: SwapModule.Dex { service.dex }
    var isEstimated: Bool { false }
    var amount: Decimal { tradeService.amountIn }
    var platformCoin: PlatformCoin? { tradeService.platformCoinIn }
    var balance: Decimal? { service.balanceIn }

    var isEstimatedObservable: Observable<Bool> { Observable.just(true) }
    var amountObservable: Observable<Decimal> { tradeService.amountInObservable }
    var platformCoinObservable: Observable<PlatformCoin?> { tradeService.platformCoinInObservable }
    var balanceObservable: Observable<Decimal?> { service.balanceInObservable }
    var errorObservable: Observable<Error?> {
        service.errorsObservable.map {
            $0.first(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError })
        }
    }

    func onChange(amount: Decimal) {
        tradeService.set(amountIn: amount)
    }

    func onChange(platformCoin: PlatformCoin) {
        tradeService.set(platformCoinIn: platformCoin)
    }

}

class SwapToCoinCardOneInchService: ISwapCoinCardService, IAmountInputService {
    private let service: OneInchService
    private let tradeService: OneInchTradeService

    init(service: OneInchService, tradeService: OneInchTradeService) {
        self.service = service
        self.tradeService = tradeService
    }

    var dex: SwapModule.Dex { service.dex }
    var readOnly: Bool { true }
    var isEstimated: Bool { true }
    var amount: Decimal { tradeService.amountOut }
    var platformCoin: PlatformCoin? { tradeService.platformCoinOut }
    var balance: Decimal? { service.balanceOut }

    var readOnlyObservable: Observable<Bool> { Observable.just(true) }
    var isEstimatedObservable: Observable<Bool> { Observable.just(false) }
    var amountObservable: Observable<Decimal> { tradeService.amountOutObservable }
    var platformCoinObservable: Observable<PlatformCoin?> { tradeService.platformCoinOutObservable }
    var balanceObservable: Observable<Decimal?> { service.balanceOutObservable }
    var errorObservable: Observable<Error?> {
        Observable<Error?>.just(nil)
    }

    func onChange(amount: Decimal) {
        // can't change to-card
    }

    func onChange(platformCoin: PlatformCoin) {
        tradeService.set(platformCoinOut: platformCoin)
    }

}
