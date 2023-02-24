import SectionsTableView
import UIKit
import ThemeKit
import MarketKit
import EvmKit

struct SendSettingsModule {

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

protocol ISendSettingsDataSource: AnyObject {
    var tableView: SectionsTableView? { get set }
    var onOpenInfo: ((String, String) -> ())? { get set }
    var present: ((UIViewController) -> ())? { get set }
    var onUpdateAlteredState: (() -> ())? { get set }

    var altered: Bool { get }
    var buildSections: [SectionProtocol] { get }

    func onTapReset()
    func viewDidLoad()
}
