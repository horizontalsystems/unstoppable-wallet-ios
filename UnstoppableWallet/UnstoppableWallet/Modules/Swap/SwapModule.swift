import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import EthereumKit
import ThemeKit
import CurrencyKit
import BigInt
import CoinKit

//TODO: move to another place
func subscribe<T>(_ disposeBag: DisposeBag, _ driver: Driver<T>, _ onNext: ((T) -> Void)? = nil) {
    driver.drive(onNext: onNext).disposed(by: disposeBag)
}

func subscribe<T>(_ disposeBag: DisposeBag, _ signal: Signal<T>, _ onNext: ((T) -> Void)? = nil) {
    signal.emit(onNext: onNext).disposed(by: disposeBag)
}

func subscribe<T>(_ disposeBag: DisposeBag, _ observable: Observable<T>, _ onNext: ((T) -> Void)? = nil) {
    observable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: onNext)
            .disposed(by: disposeBag)
}

func subscribe<T>(_ scheduler: ImmediateSchedulerType, _ disposeBag: DisposeBag, _ observable: Observable<T>, _ onNext: ((T) -> Void)? = nil) {
    observable
            .observeOn(scheduler)
            .subscribe(onNext: onNext)
            .disposed(by: disposeBag)
}

struct SwapModule {

    struct ConfirmationAdditionalViewItem {
        let title: String
        let value: String?
    }

    struct ConfirmationAmountViewItem {
        let payTitle: String
        let payValue: String?
        let getTitle: String
        let getValue: String?
    }

    struct PriceImpactViewItem {
        let value: String
        let level: SwapTradeService.PriceImpactLevel
    }

    struct GuaranteedAmountViewItem {
        let title: String
        let value: String
    }

    static func viewController(coinIn: Coin) -> UIViewController? {
        switch coinIn.type {
        case .ethereum, .erc20: return viewController(dex: .uniswap, coinIn: coinIn)
        case .binanceSmartChain, .bep20: return viewController(dex: .pancake, coinIn: coinIn)
        default: return nil
        }
    }

    static func viewController(dex: Dex, coinIn: Coin? = nil) -> UIViewController? {
        guard let evmKit = dex.evmKit else {
            return nil
        }

        let swapKit = UniswapKit.Kit.instance(evmKit: evmKit)
        let uniswapRepository = UniswapProvider(swapKit: swapKit)

        let tradeService = SwapTradeService(
                uniswapProvider: uniswapRepository,
                coin: coinIn,
                evmKit: evmKit
        )
        let allowanceService = SwapAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                evmKit: evmKit
        )
        let pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                allowanceService: allowanceService
        )
        let service = SwapService(
                dex: dex,
                evmKit: evmKit,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                adapterManager: App.shared.adapterManager
        )

        let allowanceViewModel = SwapAllowanceViewModel(service: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = SwapViewModel(
                service: service,
                tradeService: tradeService,
                switchService: AmountTypeSwitchService(),
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                viewItemHelper: SwapViewItemHelper()
        )

        let viewController = SwapViewController(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension SwapModule {

    enum Dex {
        case uniswap
        case pancake

        var evmKit: EthereumKit.Kit? {
            switch self {
            case .uniswap: return App.shared.ethereumKitManager.evmKit
            case .pancake: return App.shared.binanceSmartChainKitManager.evmKit
            }
        }

        var coin: Coin? {
            switch self {
            case .uniswap: return App.shared.coinKit.coin(type: .ethereum)
            case .pancake: return App.shared.coinKit.coin(type: .binanceSmartChain)
            }
        }

    }

}

extension UniswapKit.Kit.TradeError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .tradeNotFound: return "swap.trade_error.not_found".localized
        default: return nil
        }
    }

}
