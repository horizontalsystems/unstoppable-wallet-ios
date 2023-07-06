import UIKit
import ComponentKit

struct CexDepositModule {

    static func viewController(cexAsset: CexAsset) -> UIViewController? {
        if cexAsset.depositNetworks.isEmpty {
            return viewController(cexAsset: cexAsset, network: nil)
        } else if cexAsset.depositNetworks.count == 1 {
            return viewController(cexAsset: cexAsset, network: cexAsset.depositNetworks[0])
        } else {
            return CexDepositNetworkSelectModule.viewController(cexAsset: cexAsset)
        }
    }

    static func viewController(cexAsset: CexAsset, network: CexDepositNetwork?) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        let provider = App.shared.cexProviderFactory.provider(type: type)

        let service = CexDepositService(cexAsset: cexAsset, network: network, provider: provider)
        let viewModel = CexDepositViewModel(service: service)
        return CexDepositViewController(viewModel: viewModel)
    }

}
