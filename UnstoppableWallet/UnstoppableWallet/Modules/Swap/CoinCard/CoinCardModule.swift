import UniswapKit
import RxSwift
import CoinKit

protocol ISwapCoinCardService: AnyObject {
    var dex: SwapModule.Dex { get }
    var isEstimated: Bool { get }
    var coin: Coin? { get }
    var balance: Decimal? { get }

    var isEstimatedObservable: Observable<Bool> { get }
    var coinObservable: Observable<Coin?> { get }
    var balanceObservable: Observable<Decimal?> { get }
    var errorObservable: Observable<Error?> { get }

    func onChange(coin: Coin)
}

struct CoinCardModule {

    static func fromCell(service: SwapService, tradeService: SwapTradeService, switchService: AmountTypeSwitchService) -> SwapCoinCardCell {
        let coinCardService = SwapFromCoinCardService(service: service, tradeService: tradeService)

        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
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

    static func toCell(service: SwapService, tradeService: SwapTradeService, switchService: AmountTypeSwitchService) -> SwapCoinCardCell {
        let coinCardService = SwapToCoinCardService(service: service, tradeService: tradeService)

        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
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
    private let service: SwapService
    private let tradeService: SwapTradeService

    init(service: SwapService, tradeService: SwapTradeService) {
        self.service = service
        self.tradeService = tradeService
    }

    var dex: SwapModule.Dex { service.dex }
    var isEstimated: Bool { tradeService.tradeType != .exactIn }
    var amount: Decimal { tradeService.amountIn }
    var coin: Coin? { tradeService.coinIn }
    var balance: Decimal? { service.balanceIn }

    var isEstimatedObservable: Observable<Bool> { tradeService.tradeTypeObservable.map { $0 != .exactIn } }
    var amountObservable: Observable<Decimal> { tradeService.amountInObservable }
    var coinObservable: Observable<Coin?> { tradeService.coinInObservable }
    var balanceObservable: Observable<Decimal?> { service.balanceInObservable }
    var errorObservable: Observable<Error?> {
        service.errorsObservable.map {
            $0.first(where: { .insufficientBalanceIn == $0 as? SwapService.SwapError })
        }
    }

    func onChange(amount: Decimal) {
        tradeService.set(amountIn: amount)
    }

    func onChange(coin: Coin) {
        tradeService.set(coinIn: coin)
    }

}

class SwapToCoinCardService: ISwapCoinCardService, IAmountInputService {
    private let service: SwapService
    private let tradeService: SwapTradeService

    init(service: SwapService, tradeService: SwapTradeService) {
        self.service = service
        self.tradeService = tradeService
    }

    var dex: SwapModule.Dex { service.dex }
    var isEstimated: Bool { tradeService.tradeType != .exactOut }
    var amount: Decimal { tradeService.amountOut }
    var coin: Coin? { tradeService.coinOut }
    var balance: Decimal? { service.balanceOut }

    var isEstimatedObservable: Observable<Bool> { tradeService.tradeTypeObservable.map { $0 != .exactOut } }
    var amountObservable: Observable<Decimal> { tradeService.amountOutObservable }
    var coinObservable: Observable<Coin?> { tradeService.coinOutObservable }
    var balanceObservable: Observable<Decimal?> { service.balanceOutObservable }
    var errorObservable: Observable<Error?> {
        Observable<Error?>.just(nil)
    }

    func onChange(amount: Decimal) {
        tradeService.set(amountOut: amount)
    }

    func onChange(coin: Coin) {
        tradeService.set(coinOut: coin)
    }

}
