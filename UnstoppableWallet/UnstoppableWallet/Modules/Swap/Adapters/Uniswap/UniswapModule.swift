import UniswapKit
import EthereumKit

class UniswapModule {
    private let tradeService: UniswapTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: UniswapService

    init?(dex: SwapModule.Dex, dataSourceState: SwapModule.DataSourceState) {
        guard let evmKit = dex.blockchain.evmKit else {
            return nil
        }

        let swapKit = UniswapKit.Kit.instance(evmKit: evmKit)
        let uniswapRepository = UniswapProvider(swapKit: swapKit)

        tradeService = UniswapTradeService(
                uniswapProvider: uniswapRepository,
                state: dataSourceState,
                evmKit: evmKit
        )
        allowanceService = SwapAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManagerNew,
                evmKit: evmKit
        )
        pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManagerNew,
                allowanceService: allowanceService
        )
        service = UniswapService(
                dex: dex,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                adapterManager: App.shared.adapterManagerNew
        )
    }

}

extension UniswapModule: ISwapProvider {

    var dataSource: ISwapDataSource {
        let allowanceViewModel = SwapAllowanceViewModel(errorProvider: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = UniswapViewModel(
                service: service,
                tradeService: tradeService,
                switchService: AmountTypeSwitchService(),
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                viewItemHelper: SwapViewItemHelper()
        )

        return UniswapDataSource(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel
        )
    }

    var settingsDataSource: ISwapSettingsDataSource? {
        UniswapSettingsModule.dataSource(tradeService: tradeService)
    }

    var swapState: SwapModule.DataSourceState {
        let exactIn = tradeService.tradeType == .exactIn

        return SwapModule.DataSourceState(
                platformCoinFrom: tradeService.platformCoinIn,
                platformCoinTo: tradeService.platformCoinOut,
                amountFrom: tradeService.amountIn,
                amountTo: tradeService.amountOut,
                exactFrom: exactIn)
    }

}

extension UniswapModule {

    struct PriceImpactViewItem {
        let value: String
        let level: UniswapTradeService.PriceImpactLevel
    }

    struct GuaranteedAmountViewItem {
        let title: String
        let value: String
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
