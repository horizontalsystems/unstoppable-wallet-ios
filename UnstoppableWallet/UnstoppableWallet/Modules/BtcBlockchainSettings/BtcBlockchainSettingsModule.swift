import UIKit
import ThemeKit
import MarketKit

protocol IBtcBlockchainSettingsDelegate: AnyObject {
    func didApprove(coinSettingsArray: [CoinSettings])
    func didCancel()
}

struct BtcBlockchainSettingsModule {

    static func viewController(config: Config, delegate: IBtcBlockchainSettingsDelegate? = nil) -> UIViewController {
        let service = BtcBlockchainSettingsService(config: config, walletManager: App.shared.walletManager)
        let viewModel = BtcBlockchainSettingsViewModel(service: service)
        let viewController = BtcBlockchainSettingsViewController(viewModel: viewModel, delegate: delegate)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension BtcBlockchainSettingsModule {

    struct Config {
        let blockchain: Blockchain
        let accountType: AccountType
        let accountOrigin: AccountOrigin
        let coinSettingsArray: [CoinSettings]
        let mode: Mode
    }

    enum Mode {
        case restore(initial: Bool)
        case manage(initial: Bool)
        case changeSource(wallet: Wallet)

        var initial: Bool {
            switch self {
            case .restore(let initial): return initial
            case .manage(let initial): return initial
            case .changeSource: return false
            }
        }

        var approveApplyRequired: Bool {
            switch self {
            case .restore: return false
            case .manage(let initial): return !initial
            case .changeSource: return true
            }
        }

        var addressFormatHidden: Bool {
            switch self {
            case .changeSource: return true
            default: return false
            }
        }

        var autoSave: Bool {
            switch self {
            case .changeSource: return true
            default: return false
            }
        }
    }

}
