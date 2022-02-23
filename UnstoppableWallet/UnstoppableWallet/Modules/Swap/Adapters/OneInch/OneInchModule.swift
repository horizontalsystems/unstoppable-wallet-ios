import OneInchKit
import EthereumKit
import StorageKit

class OneInchModule {
    private let tradeService: OneInchTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: OneInchService

    init?(dex: SwapModule.Dex, dataSourceState: SwapModule.DataSourceState) {
        guard let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchain: dex.blockchain).evmKitWrapper?.evmKit else {
            return nil
        }

        guard let swapKit = try? OneInchKit.Kit.instance(evmKit: evmKit) else {
            return nil
        }

        let oneInchProvider = OneInchProvider(swapKit: swapKit)

        tradeService = OneInchTradeService(
                oneInchProvider: oneInchProvider,
                state: dataSourceState,
                evmKit: evmKit
        )
        allowanceService = SwapAllowanceService(
                spenderAddress: oneInchProvider.routerAddress,
                adapterManager: App.shared.adapterManager,
                evmKit: evmKit
        )
        pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: oneInchProvider.routerAddress,
                adapterManager: App.shared.adapterManager,
                allowanceService: allowanceService
        )
        service = OneInchService(
                dex: dex,
                evmKit: evmKit,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                adapterManager: App.shared.adapterManager
        )
    }

}

extension OneInchModule: ISwapProvider {

    var dataSource: ISwapDataSource {
        let allowanceViewModel = SwapAllowanceViewModel(errorProvider: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = OneInchViewModel(
                service: service,
                tradeService: tradeService,
                switchService: AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default),
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
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
                platformCoinFrom: tradeService.platformCoinIn,
                platformCoinTo: tradeService.platformCoinOut,
                amountFrom: tradeService.amountIn,
                amountTo: tradeService.amountOut,
                exactFrom: true)
    }

}
