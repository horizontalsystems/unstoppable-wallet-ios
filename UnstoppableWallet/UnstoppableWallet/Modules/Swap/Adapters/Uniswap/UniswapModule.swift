import UniswapKit
import EthereumKit

class UniswapModule {
    private let tradeService: UniswapTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: UniswapService

    init?(dex: SwapModuleNew.DexNew, dataSourceState: SwapModuleNew.DataSourceState) {
        guard let evmKit = dex.evmKit else {
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
                walletManager: App.shared.walletManager,
                evmKit: evmKit
        )
        pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                walletManager: App.shared.walletManager,
                allowanceService: allowanceService
        )
        service = UniswapService(
                dex: dex,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                walletManager: App.shared.walletManager
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

    var swapState: SwapModuleNew.DataSourceState {
        let exactIn = tradeService.tradeType == .exactIn

        return SwapModuleNew.DataSourceState(
                coinFrom: tradeService.coinIn,
                coinTo: tradeService.coinOut,
                amountFrom: tradeService.amountIn,
                amountTo: tradeService.amountOut,
                exactFrom: exactIn)
    }

}
