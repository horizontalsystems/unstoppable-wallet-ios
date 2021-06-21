import OneInchKit
import EthereumKit

class OneInchModule {
    private let tradeService: OneInchTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: OneInchService

    init?(dex: SwapModuleNew.DexNew, dataSourceState: SwapModuleNew.DataSourceState) {
        guard let evmKit = dex.evmKit else {
            return nil
        }

        let swapKit = OneInchKit.Kit.instance(evmKit: evmKit)
        let oneInchRepository = OneInchProvider(swapKit: swapKit)

        tradeService = OneInchTradeService(
                oneInchProvider: oneInchRepository,
                state: dataSourceState,
                evmKit: evmKit
        )
        allowanceService = SwapAllowanceService(
                spenderAddress: oneInchRepository.routerAddress,
                walletManager: App.shared.walletManager,
                evmKit: evmKit
        )
        pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: oneInchRepository.routerAddress,
                walletManager: App.shared.walletManager,
                allowanceService: allowanceService
        )
        service = OneInchService(
                dex: dex,
                evmKit: evmKit,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                walletManager: App.shared.walletManager
        )
    }

}

extension OneInchModule: ISwapProvider {

    var swapDataSource: ISwapDataSource {
        let allowanceViewModel = SwapAllowanceViewModel(errorProvider: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = OneInchViewModel(
                service: service,
                tradeService: tradeService,
                switchService: AmountTypeSwitchService(),
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                viewItemHelper: SwapViewItemHelper()
        )

        return OneInchDataSource(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel
        )
    }

    var swapSettingsDataSource: ISwapSettingsDataSource? {
        OneInchSettingsModule.dataSource(tradeService: tradeService)
    }

    var swapState: SwapModuleNew.DataSourceState {
        SwapModuleNew.DataSourceState(
                coinFrom: tradeService.coinIn,
                coinTo: tradeService.coinOut,
                amountFrom: tradeService.amountIn,
                amountTo: tradeService.amountOut,
                exactFrom: true)
    }

}
