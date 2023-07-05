import Foundation
import UniswapKit
import EvmKit
import StorageKit

class UniswapV3Module {
    private let tradeService: UniswapV3TradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: UniswapV3Service

    init?(dex: SwapModule.Dex, dataSourceState: SwapModule.DataSourceState) {
        guard let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper?.evmKit else {
            return nil
        }

        guard let swapKit = try? UniswapKit.KitV3.instance(evmKit: evmKit, dexType: dex.provider.dexType) else {
            return nil
        }

        let uniswapRepository = UniswapV3Provider(swapKit: swapKit)

        tradeService = UniswapV3TradeService(
                uniswapProvider: uniswapRepository,
                state: dataSourceState,
                evmKit: evmKit
        )
        allowanceService = SwapAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                evmKit: evmKit
        )
        pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                allowanceService: allowanceService
        )
        service = UniswapV3Service(
                dex: dex,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                adapterManager: App.shared.adapterManager
        )
    }

}

extension UniswapV3Module: ISwapProvider {

    var dataSource: ISwapDataSource {
        let allowanceViewModel = SwapAllowanceViewModel(errorProvider: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = UniswapV3ViewModel(
                service: service,
                tradeService: tradeService,
                switchService: AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default, useLocalStorage: false),
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                currencyKit: App.shared.currencyKit,
                viewItemHelper: SwapViewItemHelper()
        )

        return UniswapV3DataSource(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel
        )
    }

    var settingsDataSource: ISwapSettingsDataSource? {
        UniswapSettingsModule.dataSource(settingProvider: tradeService, showDeadline: false)
    }

    var swapState: SwapModule.DataSourceState {
        let exactIn = tradeService.tradeType == .exactIn

        return SwapModule.DataSourceState(
                tokenFrom: tradeService.tokenIn,
                tokenTo: tradeService.tokenOut,
                amountFrom: tradeService.amountIn,
                amountTo: tradeService.amountOut,
                exactFrom: exactIn)
    }

}

extension UniswapV3Module {

    struct PriceImpactViewItem {
        let value: String
        let level: UniswapTradeService.PriceImpactLevel
    }

    struct GuaranteedAmountViewItem {
        let title: String
        let value: String?
    }

    enum UniswapWarning: Warning {
        case highPriceImpact
    }

    enum TradeError: Error {
        case wrapUnwrapNotAllowed
    }

}
