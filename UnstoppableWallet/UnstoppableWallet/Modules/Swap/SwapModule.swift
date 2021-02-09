import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import EthereumKit
import ThemeKit
import CurrencyKit
import BigInt

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
        guard let ethereumKit = App.shared.ethereumKitManager.ethereumKit else {
            return nil
        }

        let swapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        let uniswapRepository = UniswapProvider(swapKit: swapKit)

        let coinService = CoinService(
                coin: App.shared.appConfigProvider.ethereumCoin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let tradeService = SwapTradeService(
                uniswapProvider: uniswapRepository,
                coin: coinIn,
                ethereumKit: ethereumKit
        )
        let allowanceService = SwapAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                ethereumKit: ethereumKit
        )
        let pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                allowanceService: allowanceService
        )
        let transactionService = EthereumTransactionService(
                ethereumKit: ethereumKit,
                feeRateProvider: App.shared.feeRateProviderFactory.provider(coinType: .ethereum) as! EthereumFeeRateProvider,
                gasLimitSurchargePercent: 20
        )
        let service = SwapService(
                ethereumKit: ethereumKit,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                transactionService: transactionService,
                adapterManager: App.shared.adapterManager
        )

        let allowanceViewModel = SwapAllowanceViewModel(service: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinService)
        let viewModel = SwapViewModel(
                service: service,
                tradeService: tradeService,
                fiatSwitchService: AmountTypeSwitchService(),
                transactionService: transactionService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                coinService: coinService,
                viewItemHelper: SwapViewItemHelper()
        )

        let viewController = SwapViewController(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel,
                feeViewModel: feeViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
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
