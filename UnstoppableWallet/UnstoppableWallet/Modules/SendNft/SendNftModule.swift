import UIKit
import ThemeKit
import MarketKit
import StorageKit

class SendNftModule {

    static func viewController(nftRecord: EvmNftRecord) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }
        let nftKey = NftKey(account: account, blockchainType: nftRecord.blockchainType)
        guard let adapter = App.shared.nftAdapterManager.adapterMap[nftKey] else {
            return nil
        }

        let viewController = UIViewController()
        return ThemeNavigationController(rootViewController: viewController)
    }

}
