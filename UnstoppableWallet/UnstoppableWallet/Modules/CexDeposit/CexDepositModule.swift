import UIKit
import ComponentKit

struct CexDepositModule {

    static func viewController(cexAsset: CexAsset) -> UIViewController? {
        if cexAsset.networks.isEmpty {
            return viewController(cexAsset: cexAsset, cexNetwork: nil)
        } else if cexAsset.networks.count == 1 {
            return viewController(cexAsset: cexAsset, cexNetwork: cexAsset.networks[0])
        } else {
            return CexDepositNetworkSelectModule.viewController(cexAsset: cexAsset)
        }
    }

    static func viewController(cexAsset: CexAsset, cexNetwork: CexNetwork?) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        let provider = App.shared.cexProviderFactory.provider(type: type)

        let service = CexDepositService(cexAsset: cexAsset, cexNetwork: cexNetwork, provider: provider)
        let viewModel = CexDepositViewModel(service: service)
        return CexDepositViewController(viewModel: viewModel)
    }

}
