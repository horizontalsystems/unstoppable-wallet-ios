import SectionsTableView
import UIKit
import ThemeKit
import MarketKit
import EvmKit

struct EvmSendSettingsModule {

    static func instance(evmKit: EvmKit.Kit, blockchainType: BlockchainType, sendData: SendEvmData, coinServiceFactory: EvmCoinServiceFactory,
                         gasPrice: GasPrice? = nil, previousTransaction: EvmKit.Transaction? = nil,
                         gasLimit: Int? = nil, gasLimitSurchargePercent: Int = 0) -> (EvmSendSettingsService, EvmFeeViewModel) {
        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKit, gasPrice: gasPrice, previousTransaction: previousTransaction)
        let gasDataService = EvmCommonGasDataService.instance(evmKit: evmKit, blockchainType: blockchainType, gasLimit: gasLimit, gasLimitSurchargePercent: gasLimitSurchargePercent)
        let feeService = EvmFeeService(evmKit: evmKit, gasPriceService: gasPriceService, gasDataService: gasDataService, coinService: coinServiceFactory.baseCoinService, transactionData: sendData.transactionData)
        let nonceService = NonceService(evmKit: evmKit, replacingNonce: previousTransaction?.nonce)
        let service = EvmSendSettingsService(feeService: feeService, nonceService: nonceService)

        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        return (service, feeViewModel)
    }

    static func viewController(settingsService: EvmSendSettingsService) -> UIViewController? {
        let feeService = settingsService.feeService
        let coinService = feeService.coinService
        let gasPriceService = feeService.gasPriceService
        let feeViewItemFactory = FeeViewItemFactory(scale: coinService.token.blockchainType.feePriceScale)
        let cautionsFactory = SendEvmCautionsFactory()

        let nonceService = settingsService.nonceService
        let nonceViewModel = NonceViewModel(service: nonceService)
        let nonceDataSource = NonceDataSource(viewModel: nonceViewModel)

        switch gasPriceService {
        case let legacyService as LegacyGasPriceService:
            let dataSourceViewModel = LegacyEvmFeeViewModel(gasPriceService: legacyService, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory)
            let dataSources: [IEvmSendSettingsDataSource] = [
                LegacyEvmFeeDataSource(viewModel: dataSourceViewModel),
                nonceDataSource
            ]

            let viewModel = EvmSendSettingsViewModel(service: settingsService, cautionsFactory: cautionsFactory)

            return ThemeNavigationController(rootViewController: EvmSendSettingsViewController(viewModel: viewModel, dataSources: dataSources))

        case let eip1559Service as Eip1559GasPriceService:
            let dataSourceViewModel = Eip1559EvmFeeViewModel(gasPriceService: eip1559Service, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory)
            let dataSources: [IEvmSendSettingsDataSource] = [
                Eip1559EvmFeeDataSource(viewModel: dataSourceViewModel),
                nonceDataSource
            ]

            let viewModel = EvmSendSettingsViewModel(service: settingsService, cautionsFactory: cautionsFactory)

            return ThemeNavigationController(rootViewController: EvmSendSettingsViewController(viewModel: viewModel, dataSources: dataSources))

        default: return nil
        }
    }

}

protocol IEvmSendSettingsDataSource: AnyObject {
    var tableView: SectionsTableView? { get set }
    var onOpenInfo: ((String, String) -> ())? { get set }
    var onUpdateAlteredState: (() -> ())? { get set }

    var altered: Bool { get }
    var buildSections: [SectionProtocol] { get }

    func onTapReset()
    func viewDidLoad()
}
