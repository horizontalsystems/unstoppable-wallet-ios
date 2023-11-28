import EvmKit
import SectionsTableView
import ThemeKit
import UIKit

protocol ISwapSettingsDataSource: AnyObject {
    func viewDidLoad()
    func buildSections(tableView: SectionsTableView) -> [SectionProtocol]
    func didTapApply()

    var onOpen: ((UIViewController) -> Void)? { get set }
    var onClose: (() -> Void)? { get set }
    var onReload: (() -> Void)? { get set }
    var onChangeButtonState: ((Bool, String) -> Void)? { get set }
}

enum SwapSettingsModule {
    static func viewController(dataSourceManager: ISwapDataSourceManager, dexManager _: ISwapDexManager) -> UIViewController? {
        let viewController = SwapSettingsViewController(dataSourceManager: dataSourceManager)
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
