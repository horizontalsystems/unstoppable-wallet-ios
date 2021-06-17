import UIKit
import CoinKit
import EthereumKit
import SectionsTableView
import ThemeKit

protocol ISwapSettingsDataSource: AnyObject {
    func viewDidLoad()
    func buildSections() -> [SectionProtocol]

    var onOpen: ((UIViewController) -> ())? { get set }
    var onClose: (() -> ())? { get set }
    var onReload: (() -> ())? { get set }
}

class SwapSettingsModule {

    static func viewController(swapDataSourceManager: SwapProviderManager) -> UIViewController? {
        let service = SwapSettingsService()

        let viewModel = SwapSettingsViewModel(service: service, swapDataSourceManager: swapDataSourceManager)
        let viewController = SwapSettingsViewController(
                viewModel: viewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension SwapSettingsModule {

    enum AddressError: Error {
        case invalidAddress
    }

    enum SlippageError: Error {
        case zeroValue
        case tooLow(min: Decimal)
        case tooHigh(max: Decimal)
    }

    enum DeadlineError: Error {
        case zeroValue
    }

}