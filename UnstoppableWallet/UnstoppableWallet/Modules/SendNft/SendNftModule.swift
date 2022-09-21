import UIKit
import ThemeKit
import MarketKit

class SendNftModule {

    static func viewController(nftUid: NftUid) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount, !account.watchAccount else {
            return nil
        }

        let nftKey = NftKey(account: account, blockchainType: nftUid.blockchainType)

        guard let adapter = App.shared.nftAdapterManager.adapter(nftKey: nftKey) else {
            return nil
        }

        guard let nftRecord = adapter.nftRecord(nftUid: nftUid) else {
            return nil
        }

        let viewController: UIViewController

        switch nftUid {
        case .evm:
            guard let evmNftRecord = nftRecord as? EvmNftRecord else {
                return nil
            }

            switch evmNftRecord.type {
            case .eip721:
                viewController = UIViewController()
            case .eip1155:
                viewController = UIViewController()
            }

        default:
            return nil
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

}
