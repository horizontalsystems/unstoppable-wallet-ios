import SectionsTableView
import UIKit
import ThemeKit
import MarketKit
import EvmKit

struct EvmSendSettingsModule {

    static func instance(evmKit: EvmKit.Kit, blockchainType: BlockchainType, sendData: SendEvmData, coinServiceFactory: EvmCoinServiceFactory,
                         gasPrice: GasPrice? = nil, previousTransaction: EvmKit.Transaction? = nil,
                         predefinedGasLimit: Int? = nil) -> (EvmSendSettingsService, EvmSendSettingsViewModel)? {
        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKit, gasPrice: gasPrice, previousTransaction: previousTransaction)

        let gasDataService = EvmCommonGasDataService.instance(
                evmKit: evmKit,
                blockchainType: blockchainType,
                predefinedGasLimit: predefinedGasLimit
        )

        let coinService = coinServiceFactory.baseCoinService
        let feeViewItemFactory = FeeViewItemFactory(scale: coinService.token.blockchainType.feePriceScale)
        let feeService = EvmFeeService(evmKit: evmKit, gasPriceService: gasPriceService, gasDataService: gasDataService, coinService: coinService, transactionData: sendData.transactionData)
        let nonceService = NonceService(evmKit: evmKit, replacingNonce: previousTransaction?.nonce)
        let service = EvmSendSettingsService(feeService: feeService, nonceService: nonceService)

        let cautionsFactory = SendEvmCautionsFactory()
        let nonceViewModel = NonceViewModel(service: nonceService)

        let viewModel: EvmSendSettingsViewModel
        switch gasPriceService {
        case let legacyService as LegacyGasPriceService:
            let feeViewModel = LegacyEvmFeeViewModel(gasPriceService: legacyService, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory)
            viewModel = EvmSendSettingsViewModel(service: service, feeViewModel: feeViewModel, nonceViewModel: nonceViewModel, cautionsFactory: cautionsFactory)

        case let eip1559Service as Eip1559GasPriceService:
            let feeViewModel = Eip1559EvmFeeViewModel(gasPriceService: eip1559Service, feeService: feeService, coinService: coinService, feeViewItemFactory: feeViewItemFactory)
            viewModel = EvmSendSettingsViewModel(service: service, feeViewModel: feeViewModel, nonceViewModel: nonceViewModel, cautionsFactory: cautionsFactory)

        default: return nil
        }

        return (service, viewModel)
    }

    static func viewController(settingsViewModel: EvmSendSettingsViewModel) -> UIViewController? {
        let nonceViewModel = settingsViewModel.nonceViewModel
        let nonceDataSource = NonceDataSource(viewModel: nonceViewModel)

        let feeDataSource: IEvmSendSettingsDataSource
        switch settingsViewModel.feeViewModel {
        case let viewModel as LegacyEvmFeeViewModel:
            feeDataSource = LegacyEvmFeeDataSource(viewModel: viewModel)

        case let viewModel as Eip1559EvmFeeViewModel:
            feeDataSource = Eip1559EvmFeeDataSource(viewModel: viewModel)

        default: return nil
        }

        let settingsViewController = EvmSendSettingsViewController(viewModel: settingsViewModel, dataSources: [feeDataSource, nonceDataSource])

        return ThemeNavigationController(rootViewController: settingsViewController)
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
