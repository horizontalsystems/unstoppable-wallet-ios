import UIKit
import ThemeKit
import MarketKit

protocol ContactBookSelectorDelegate: AnyObject {
    func onFetch(address: String)
}

struct ContactBookModule {

    static func viewController(mode: Mode, presented: Bool = false) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

        let service = ContactBookService(contactManager: contactManager, blockchainType: mode.blockchainType)
        let viewModel = ContactBookViewModel(service: service)

        let viewController = ContactBookViewController(viewModel: viewModel, presented: presented, selectorDelegate: mode.delegate)
        if presented {
            return ThemeNavigationController(rootViewController: viewController)
        } else {
            return viewController
        }
    }

}

extension ContactBookModule {

    enum Mode {
        case select(BlockchainType, ContactBookSelectorDelegate)
        case edit

        var blockchainType: BlockchainType? {
            switch self {
            case .select(let blockchainType, _): return blockchainType
            default: return nil
            }
        }

        var delegate: ContactBookSelectorDelegate? {
            switch self {
            case .select(_, let delegate): return delegate
            default: return nil
            }
        }
    }

}
