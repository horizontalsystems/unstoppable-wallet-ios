import EvmKit
import OneInchKit

class OneInchModule {
    private let tradeService: OneInchTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: OneInchService

    init?(dex: SwapModule.Dex, dataSourceState: SwapModule.DataSourceState) {
        guard let evmKit = Core.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper?.evmKit else {
            return nil
        }

        guard let apiKey = AppConfig.oneInchApiKey,
              let rpcSource = Core.shared.evmSyncSourceManager.httpSyncSource(blockchainType: dex.blockchainType)?.rpcSource
        else {
            return nil
        }

        let swapKit = OneInchKit.Kit.instance(apiKey: apiKey)
        let oneInchProvider = OneInchProvider(swapKit: swapKit, evmKit: evmKit, rpcSource: rpcSource)
        print("OneInchProvider router Address: \(oneInchProvider.routerAddress.hex)")

        tradeService = OneInchTradeService(
            oneInchProvider: oneInchProvider,
            state: dataSourceState,
            evmKit: evmKit
        )
        allowanceService = SwapAllowanceService(
            spenderAddress: oneInchProvider.routerAddress,
            adapterManager: Core.shared.adapterManager,
            evmKit: evmKit
        )
        pendingAllowanceService = SwapPendingAllowanceService(
            spenderAddress: oneInchProvider.routerAddress,
            adapterManager: Core.shared.adapterManager,
            allowanceService: allowanceService
        )
        service = OneInchService(
            dex: dex,
            evmKit: evmKit,
            tradeService: tradeService,
            allowanceService: allowanceService,
            pendingAllowanceService: pendingAllowanceService,
            adapterManager: Core.shared.adapterManager
        )
    }
}

extension OneInchModule: ISwapProvider {
    var dataSource: ISwapDataSource {
        let allowanceViewModel = SwapAllowanceViewModel(errorProvider: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = OneInchViewModel(
            service: service,
            tradeService: tradeService,
            switchService: AmountTypeSwitchService(userDefaultsStorage: Core.shared.userDefaultsStorage, useLocalStorage: false),
            allowanceService: allowanceService,
            pendingAllowanceService: pendingAllowanceService,
            currencyManager: Core.shared.currencyManager,
            viewItemHelper: SwapViewItemHelper()
        )

        return OneInchDataSource(
            viewModel: viewModel,
            allowanceViewModel: allowanceViewModel
        )
    }

    var settingsDataSource: ISwapSettingsDataSource? {
        OneInchSettingsModule.dataSource(tradeService: tradeService)
    }

    var swapState: SwapModule.DataSourceState {
        SwapModule.DataSourceState(
            tokenFrom: tradeService.tokenIn,
            tokenTo: tradeService.tokenOut,
            amountFrom: tradeService.amountIn,
            amountTo: tradeService.amountOut,
            exactFrom: true
        )
    }
}
