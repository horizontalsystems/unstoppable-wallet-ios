import Foundation
import UniswapKit
import EvmKit

class UniswapModule {
    private let tradeService: UniswapTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let service: UniswapService

    init?(dex: SwapModule.Dex, dataSourceState: SwapModule.DataSourceState) {
        guard let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper?.evmKit else {
            return nil
        }

        guard let swapKit = try? UniswapKit.Kit.instance(evmKit: evmKit) else {
            return nil
        }

        let uniswapRepository = UniswapProvider(swapKit: swapKit)

        tradeService = UniswapTradeService(
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
        service = UniswapService(
                dex: dex,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                adapterManager: App.shared.adapterManager
        )
    }

}

extension UniswapModule: ISwapProvider {

    var dataSource: ISwapDataSource {
        let allowanceViewModel = SwapAllowanceViewModel(errorProvider: service, allowanceService: allowanceService, pendingAllowanceService: pendingAllowanceService)
        let viewModel = UniswapViewModel(
                service: service,
                tradeService: tradeService,
                switchService: AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage, useLocalStorage: false),
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                currencyManager: App.shared.currencyManager,
                viewItemHelper: SwapViewItemHelper()
        )

        return UniswapDataSource(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel
        )
    }

    var settingsDataSource: ISwapSettingsDataSource? {
        UniswapSettingsModule.dataSource(settingProvider: tradeService, showDeadline: true)
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

extension UniswapModule {

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
        case forbiddenPriceImpact
    }

    enum UniswapError: Error {
        case forbiddenPriceImpact(provider: String)
    }

    enum TradeError: Error {
        case wrapUnwrapNotAllowed
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

extension UniswapModule.TradeError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .wrapUnwrapNotAllowed: return "swap.trade_error.wrap_unwrap_not_allowed".localized
        }
    }

}
